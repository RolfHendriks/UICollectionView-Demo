//
//  PhotoCollectionViewController.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "PhotoCollectionViewController.h"
#import "PhotoCollectionViewCell.h"
#import "ImageDataProvider.h"
#import "RHParallaxScroller.h"
#import "RHGridCollectionView.h"

#define kPhotoFolder @"Photos"

#define kImageProviderMaximumDelay 2    // maximum simulated network delay

#define kImageHighlightScale 1.05
#define kImageHighlightAnimationDuration .5
#define kImageHighlightAnimationSpringDamping .4

#define kImageUnhighlightAnimationDuration .5
#define kImageUnhighlightAnimationSpringDamping 0.33

#define kFlashHighlightOpacity .25
#define kFlashUnhighlightDuration .5

#define kListCellAspectRatio 2
#define kListCellSpacing 8
#define kListCellParallaxRelative 0.1

#define kGridCellSize CGSizeMake (148,148)  // configured so that we fit exactly two columns on smallest 320px wide for factor
#define kGridCellSpacing CGPointMake (8,8)
#define kGridCellMargin UIEdgeInsetsMake (8,8,8,8)
#define kGridCellParallax 10
#define kGridCellHighlightScale CGPointMake (1.05, 1.05)
#define kGridCellHighlightDuration .5
#define kGridCellHighlightSpringDamping .4

#define kPhotoDetailTransitionDuration 0.5
#define kPhotoDetailTransitionSpringDamping 0.5

@interface PhotoCollectionViewController()
@property (strong, nonatomic) ImageDataProvider* images;
@property (strong, nonatomic) UIImage* placeholderPhoto;
@property (strong, nonatomic) UIImage* alternatePlaceholderPhoto;
@property (strong, nonatomic) NSString* reuseIdentifier;
@property (assign, nonatomic) CGFloat maximumParallaxScroll;
@property (assign, nonatomic) BOOL isConfigured;
@end

@implementation PhotoCollectionViewController

+ (NSString*) reuseIdentifierRegular { return @"PhotoCell"; }
+ (NSString*) reuseIdentifierWide { return @"PhotoCellWide"; }

- (NSString*) photoFolder
{
    return [[NSBundle mainBundle] pathForResource:kPhotoFolder ofType:nil];
}

- (void) commonInit
{
    // placeholder image looks arguably better on long initial loads.
    // But a blank color looks better when we show it very
    // briefly during cached loads (fast scrolling, layout changes)
    self.placeholderPhoto = [UIImage imageNamed:@"placeholder"];
    self.alternatePlaceholderPhoto = [UIImage imageNamed:@"black"];
    
    self.reuseIdentifier = [self.class reuseIdentifierRegular];
    
    ImageTestDataProvider* testImages = [ImageTestDataProvider new];
    testImages.rootFolder = [self photoFolder];
    testImages.minimumDelay = 0;
    testImages.maximumDelay = kImageProviderMaximumDelay;
    self.images = testImages;
}

- (void) fetchImageData{
    [self.images fetchDataWithResults:^(NSUInteger imageCount, NSError* error)
     {
         [self.collectionView reloadData];
     }];
}

- (instancetype) init {
    PhotoCollectionViewController* result = [[UIStoryboard storyboardWithName:@"PhotoCollectionViewController" bundle:nil] instantiateInitialViewController];
    [result commonInit];
    return result;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    [self commonInit];
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    [self commonInit];
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
    // automatically load image data when the screen appears. Deferring until
    //  viewDidAppear for two reasons: minimizing time to display the viewController,
    //  and maximizing how much time the parent viewController gets to configure the photo layout.
    BOOL dataLoaded = self.images.numberOfImages > 0;
    if (!dataLoaded)
    {
        NSAssert ( self.isConfigured, @"Must configure photo collection for grid or list view before it appears on screen");
        [self fetchImageData];
    }
    [super viewDidAppear:animated];
}



#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)sectio{
    return self.images.numberOfImages;
}

- (void) updateImageForCell:(PhotoCollectionViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary* data = [self.images dataForImageAtIndex:indexPath.item];
    
    UIImage* image = [self.images imageAtIndex:indexPath.item];
    UIImage* cellImage = cell.imageView.image;
    CGSize requestedSize = [data[kImageDataKeyRequestedSize] CGSizeValue];
    BOOL isImageLargeEnough = CGSizeEqualToSize(requestedSize, CGSizeZero) || ( requestedSize.width >= cellImage.size.width && requestedSize.height >= cellImage.size.height );
    if (image == nil || !isImageLargeEnough )
    {
        NSURL* url = [NSURL fileURLWithPath:data[kImageDataKeyFilePath]];
        image = [self.images hasCachedImageAtIndex:indexPath.item] ? self.alternatePlaceholderPhoto : self.placeholderPhoto;
        //NSLog(@"begin fetching image %@ for index %d", title, (int)indexPath.item );
        cell.downloadURL = url;
        cell.needsDownload = YES;
        CGSize imageSize = cell.bounds.size;    // this seems like a bug but actually leads to the correct results. For some reason if we reload cells immediately after a layout change, the cell size will be correct but the image size will be outdated. Calling layoutIfNeeded does not fix this.
        CGFloat scale = [[UIScreen mainScreen] scale];
        [self.images fetchImageAtIndex:indexPath.item size:imageSize scale:scale fromURL:url withResults:^(UIImage* image, NSError* error)
         {
             // NSLog(@"finished fetching image %@ for index %d", title, (int)indexPath.item);
             
             // threading issue: It's possible for this to be an outdated request
             //  from a recycled cell.
             //  The required sequence to hit this case is: begin download A, recycle cell,
             //  begin download B, end download B, end download A.
             //  The expected behavior is to prevent download A from overwriting download B.
             //  To reproduce, try reloading all images twice in a row quickly with random delays.
             BOOL isCorrectImage = cell.needsDownload && [cell.downloadURL isEqual:url];
             if (isCorrectImage)
             {
                 cell.needsDownload = NO;
                 [cell setImageAnimated:image];
             }
             else
             {
                 NSLog(@"IGNORING DOWNLOADED IMAGE. Expected URL .../%@ but got url .../%@. Most likely this image download is from a previously recycled cell that was never canceled.", url.lastPathComponent, cell.downloadURL.lastPathComponent);
             }
         }];
    }
    else
    {
        //NSLog(@"%@ at index %d has image", title, (int)indexPath.item);
        // threading special case:
        // A previously recycled instance of this cell may still have a pending image download.
        // The sequence to hit this case is: begin download, recycle cell, have cached image, end download.
        // Expected behavior is for the download not to overwrite the existing cached image.
        // To reproduce: load all images in a screen, scroll down, scroll back up before new images load.
        cell.needsDownload = NO;
    }
    cell.image = image;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    NSLog(@"Loading cell for photo #%d", (int)indexPath.item );
    
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:self.reuseIdentifier forIndexPath:indexPath];
    
    // update title
    NSMutableDictionary* data = [self.images dataForImageAtIndex:indexPath.item];
    NSString* title = data[kImageDataKeyTitle];
    cell.title = title;
    
    // update image
    [self updateImageForCell:cell atIndexPath:indexPath];
    
    // update parallax scrolling
    if (self.maximumParallaxScroll > 0 )
    {
        [RHParallaxScroller updateContentView:cell.imageView inView:cell.contentView withScroll:self.collectionView maximumParallax:self.maximumParallaxScroll];
    }

    return cell;
}

#define kPhotoCellHighlightTag 1
- (void) collectionView:(UICollectionView*)collectionView didHighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    PhotoCollectionViewCell* cell = (PhotoCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];

    if ([self isListView])
    {
        // lighten image on touch down for lists
        UIView* overlay = [cell.imageView viewWithTag:kPhotoCellHighlightTag];
        if (!overlay)
        {
            overlay = [[UIView alloc] initWithFrame:cell.imageView.bounds];
            overlay.tag = kPhotoCellHighlightTag;
            overlay.backgroundColor = [UIColor whiteColor];
            overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [cell.imageView addSubview:overlay];
        }
        overlay.alpha = kFlashHighlightOpacity;
    }
    else
    {
        // use pop scale with spring animation for grids
        [UIView animateWithDuration:kGridCellHighlightDuration delay:0 usingSpringWithDamping:kGridCellHighlightSpringDamping initialSpringVelocity:0 options:0 animations:^
         {
             cell.transform = CGAffineTransformMakeScale( kGridCellHighlightScale.x, kGridCellHighlightScale.y );
         } completion:nil];
    }
}

- (void) collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoCollectionViewCell* cell = (PhotoCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    if ( [self isListView] )
    {
        UIView* overlay = [cell.imageView viewWithTag:kPhotoCellHighlightTag];
        if (overlay)
        {
            [UIView animateWithDuration:kFlashUnhighlightDuration animations:^
            {
                overlay.alpha = 0;
            } completion:^(BOOL finished)
            {
                if (finished)
                {
                    [overlay removeFromSuperview];
                }
            }];
        }
    }
    else
    {
        [UIView animateWithDuration:kImageUnhighlightAnimationDuration delay:0 usingSpringWithDamping:kImageUnhighlightAnimationSpringDamping initialSpringVelocity:0 options:0 animations:^
         {
             cell.transform = CGAffineTransformIdentity;
         } completion:nil];
    }
}

/*
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:PhotoDetailViewController.class])
    {
        PhotoDetailViewController* details = (PhotoDetailViewController*)segue.destinationViewController;
        NSIndexPath* indexPath = [self.collectionView indexPathForCell:sender];
        NSAssert (indexPath != nil, @"Could not find index of selected photo");
        details.images = self.images;
        details.currentImage = indexPath.item;
    }
}
 */

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateParallaxScrolling];
}

- (void) updateParallaxScrolling
{
    if (self.maximumParallaxScroll > 0)
    {
        for ( PhotoCollectionViewCell* cell in self.collectionView.visibleCells )
        {
            [RHParallaxScroller updateContentView:cell.imageView inView:cell.contentView withScroll:self.collectionView maximumParallax:self.maximumParallaxScroll];
        }
    }
}

- (void) setMaximumParallaxScroll:(CGFloat)maximumParallaxScroll
{
    _maximumParallaxScroll = maximumParallaxScroll;
    [self updateParallaxScrolling];
}


- (void) reloadAll
{
    [self.images clearCache];
    [self.collectionView reloadData];
}

- (void) clearAll
{
    [self.images removeAllImages];
    [self.collectionView reloadData];
    [self fetchImageData];
}

- (void) didReceiveMemoryWarning{
    [self.images clearMemoryCache];
}

- (RHGridCollectionView*) gridCollectionView
{
    NSAssert ( [self.collectionView isKindOfClass:RHGridCollectionView.class], @"Expected photo viewController to have a grid collection view" );
    return (RHGridCollectionView*)self.collectionView;
}

- (BOOL) isListView
{
    return self.gridCollectionView.actualCellSize.width >= self.view.bounds.size.width;
}

- (void) updateVisibleCells
{
    // refreshes the UI, but without recreating any cells
    for ( NSIndexPath* visibleIndexPath in self.collectionView.indexPathsForVisibleItems )
    {
        PhotoCollectionViewCell* cell = (PhotoCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:visibleIndexPath];
        [self updateImageForCell:cell atIndexPath:visibleIndexPath];
    }
    
    [self updateParallaxScrolling];
    
    // quick + easy implementation that recreates visible cells
    //[self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
}

- (void) configureForList
{
    RHGridCollectionView* grid = [self gridCollectionView];
    CGFloat screenWidth = self.view.bounds.size.width;
    [grid setMargins:UIEdgeInsetsZero spacing:CGPointMake(0, kListCellSpacing) preferredCellSize:CGSizeMake( screenWidth, screenWidth / (CGFloat)kListCellAspectRatio)];
    [grid configureForFixedColumnCount:1];
    grid.shouldMaintainPreferredAspectRatio = YES;
    
    self.reuseIdentifier = [self.class reuseIdentifierWide];
    self.maximumParallaxScroll = grid.preferredCellSize.height * kListCellParallaxRelative;
    // only need to reload cells because we change cell style + reuse id. If we opt out of this detail, updateVisibleCells will be sufficient.
    // [self updateVisibleCells];
    [grid reloadData];
    
    self.isConfigured = YES;
}

- (void) configureForGrid
{
    RHGridCollectionView* grid = [self gridCollectionView];
    [grid setMargins:kGridCellMargin spacing:kGridCellSpacing preferredCellSize:kGridCellSize];
    [grid configureForFlexibleCellSize];
    grid.shouldMaintainPreferredAspectRatio = YES;

    self.reuseIdentifier = [self.class reuseIdentifierRegular];
    self.maximumParallaxScroll = kGridCellParallax;
    // [self updateVisibleCells];
    [grid reloadData];
    
    self.isConfigured = YES;
}

/*
 // Not ready yet: showing full screen photo viewer on selecting photo
- (PhotoDetailViewController*) instantiateDetailsForPhotoAtIndexPath:(NSIndexPath*)indexPath
{
    PhotoDetailViewController* details = [[UIStoryboard storyboardWithName:@"PhotoCollectionViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoDetailViewController"];
    details.images = self.images;
    details.currentImage = indexPath.item;
    return details;
}
*/

/**
 Reload images only on autorotation. UICollectionView changes
 position + size of cells only instead of regenerating them on size 
 change. And we want to keep this behavior for performance reasons.
 But because of how we optimize performance by downscaling photos before showing them, 
 we need to generate new photos whenever our cell size changes.
 */
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self updateVisibleCells];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    // for list views, parallax scrolling is relative to cell size, so we need to
    // update the parallax amount on size change:
    if ([self isListView])
    {
        CGFloat newCellHeight = size.width / kListCellAspectRatio;
        CGFloat newParallax = newCellHeight * kListCellParallaxRelative;
        self.maximumParallaxScroll = newParallax;
        // want to do updateParallaxScrolling, but it's too early because cells are not
        //  yet at the new size. If only there were a didTransitionToSize method. Instead
        //  we need to use the deprecated didRotateFromInterfaceOrientation.
    }
}

@end
