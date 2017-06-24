//
//  ViewController.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "MainViewController.h"
#import "PhotoCollectionViewController.h"
#import "ImageDataProvider.h"


#define kSegmentIndexGrid 0
#define kSegmentIndexList 1

// transition animation for switching segments
#define kLayoutChangeFadeOutDuration 0.2
#define kLayoutChangeFadePauseDuration 0.2
#define kLayoutChangeFadeInDuration  0.4
#define kLayoutChangeScale 0.9

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIView* photoContentView;
@property (strong, nonatomic) PhotoCollectionViewController* photoViewController;
@property (assign, nonatomic) BOOL viewDidLayout;
@end

@implementation MainViewController

#pragma mark - Toolbar

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ( self.navigationController.toolbar.items.count == 0 )
    {
        [self configureNavigationToolbar];
    }
}

- (UIBarButtonItem*) barButtonWithType:(UIBarButtonSystemItem)type action:(SEL)action
{
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:type target:self action:action];
}

- (void) configureNavigationToolbar
{
    // Want to make toolbar shrink height in landscape orientation on iPhone. We
    //  have two good but not ideal possibilities:
    //  1. Set up toolbar in Interface Builder, manage tool bar size manually (using toolbar sizeThatFits, not explicit heights)
    //  2. Set up toolbar programmatically in UINavigationController. Opt out of Interface Builder and
    //      manage removing the tool bar if needed.
    // Picking #2 to prioritize minimizing logic over using Interface Builder. #1 is nontrivial because we
    //  need to manage scroll insets in addition to toolbar sizes.
    UIBarButtonItem* clear = [self barButtonWithType:UIBarButtonSystemItemStop action:@selector(onClear)];
    UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* reload = [self barButtonWithType:UIBarButtonSystemItemRefresh action:@selector(onReload)];
    NSArray<UIBarButtonItem*>* items = @[ clear, space, reload ];
    
    [self.navigationController setToolbarHidden:NO];
    self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    self.navigationController.toolbar.tintColor = [UIColor whiteColor];
    self.navigationController.toolbar.items = self.toolbarItems = items;
}

#pragma mark - Configuration

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    UIViewController* viewController = segue.destinationViewController;
    if ([viewController isKindOfClass:PhotoCollectionViewController.class])
    {
        self.photoViewController = (PhotoCollectionViewController*)viewController;
    }
}

- (void) viewWillLayoutSubviews
{
    if (!self.viewDidLayout)
    {
        [self updatePhotosForSelection];
        self.viewDidLayout = YES;
    }
    
    [super viewWillLayoutSubviews];
}

- (void) updatePhotosForSelection
{
    if (self.segmentControl.selectedSegmentIndex == kSegmentIndexGrid)
    {
        [self.photoViewController configureForGrid];
    }
    else if (self.segmentControl.selectedSegmentIndex == kSegmentIndexList)
    {
        [self.photoViewController configureForList];
    }
    else NSLog(@"UNRECOGNIZED SELECTION");
}

- (void) viewDidLayoutSubviews
{
    // need to initialize photo layout for first time viewing. As a prerequisite, need all
    //  view frames to be correct. So we can't do this in viewDidLoad.
    if ( !self.viewDidLayout )
    {
        self.viewDidLayout = YES;
    }
    [super viewDidLayoutSubviews];
}


#pragma mark - change modes

- (void) animateOutPhotosWithDuration:(CGFloat)duration completion:(void(^)())completion
{
    UIView* collectionView = self.photoContentView;
    [UIView animateWithDuration:duration animations:^
     {
         collectionView.alpha = 0;
         //collectionView.transform = CGAffineTransformMakeScale(1.0/kLayoutChangeScale, 1.0/kLayoutChangeScale);
     }
    completion:^(BOOL finished)
    {
        if (completion) completion();
    }];
}

- (void) animateInPhotosWithDuration:(CGFloat)duration
{
    UIView* collectionView = self.photoContentView;
    //collectionView.transform = CGAffineTransformMakeScale(kLayoutChangeScale, kLayoutChangeScale);
    [UIView animateWithDuration:kLayoutChangeFadeInDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         collectionView.alpha = 1;
         //collectionView.transform = CGAffineTransformIdentity;
     }completion:nil];
}

- ( IBAction ) segmentcontrolChanged{
    // animate change im segments, mainly to mask delay from loading all images form
    // the disk cache:
    [self animateOutPhotosWithDuration:kLayoutChangeFadeOutDuration completion:^
    {
        [self updatePhotosForSelection];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kLayoutChangeFadePauseDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self animateInPhotosWithDuration:kLayoutChangeFadeInDuration];
        });
    }];
}

- (IBAction) onReload{
    NSLog(@"Reloading all photos...");
    [self.photoViewController reloadAll];
}

- (IBAction) onClear{
    NSLog(@"Clearing all photos...");
    [self.photoViewController clearAll];
}

- (void) reloadVisibleCells
{
    UICollectionView* collection = self.photoViewController.collectionView;
    [collection reloadItemsAtIndexPaths:[collection indexPathsForVisibleItems]];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (!CGSizeEqualToSize(size, self.view.bounds.size))    // don't expect this check to fail
    {
        NSTimeInterval transitionTime = coordinator.transitionDuration;
        NSTimeInterval fadeOutTime = 0.1;
        NSTimeInterval fadeInTime = kLayoutChangeFadeInDuration;
        NSTimeInterval waitTime = transitionTime - fadeOutTime + 0.1;
        
        [self animateOutPhotosWithDuration:fadeOutTime completion:^
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self animateInPhotosWithDuration:fadeInTime];
            });
        }];
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

@end
