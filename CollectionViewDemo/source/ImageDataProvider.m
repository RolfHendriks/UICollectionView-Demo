//
//  ImageProvider.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <ImageIO/ImageIO.h>

#import "ImageDataProvider.h"

@interface ImageDataProvider()
@property (strong, nonatomic) NSMutableArray<NSMutableDictionary*>* imageData;
- (NSMutableArray<NSMutableDictionary*>*) imageMetadataFromDirectory:(NSString*)path;
@end

@implementation ImageDataProvider

- (instancetype) init
{
    self = [super init];
    self.imageData = [NSMutableArray new];
    return self;
}

- (NSMutableArray<NSMutableDictionary*>*) imageMetadataFromDirectory:(NSString*)directory
{
    NSError* error = nil;
    NSArray<NSString*>* photoPathsRelative = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    if (error)
    {
        NSLog(@"FOLDER %@ NOT FOUND", directory);
    }
    
    NSMutableArray* results =
        [NSMutableArray arrayWithCapacity:photoPathsRelative.count];

    for (NSString* relativePath in photoPathsRelative)
    {
        NSDictionary* values = @
        {
        kImageDataKeyFilePath: [directory stringByAppendingPathComponent:relativePath],
        kImageDataKeyTitle: [self filenameToTitle:relativePath]
        };
        [results addObject:[values mutableCopy]];
    }

    return results;
}

- (void) loadImagesFromDirectory:(NSString *)directory
{
    self.imageData =  [self imageMetadataFromDirectory:directory];
}

- (NSUInteger) numberOfImages
{
    return self.imageData.count;
}

- (UIImage*) imageAtIndex:(NSUInteger)i
{
    NSAssert (NO, @"missing subclass implementation");
    return nil;
}

- (NSDictionary*) dataForImageAtIndex:(NSUInteger)i
{
    return self.imageData[i];
}

- (NSString*)filenameToTitle:(NSString*)filename
{
    NSMutableString* result = [filename.lastPathComponent. stringByDeletingPathExtension mutableCopy];
    NSRange fullStringRange = NSMakeRange(0, result.length);
    [result replaceOccurrencesOfString:@"-" withString:@" " options:0 range:fullStringRange];
    [result replaceOccurrencesOfString:@"_" withString:@" " options:0 range:fullStringRange];
    return [result capitalizedString];
}

- (void) fetchDataWithResults:( void (^) (NSUInteger count, NSError* error) )results
{
    NSAssert (NO, @"missing subclass implementation");
}

- (void) fetchImageAtIndex:(NSUInteger)i size:(CGSize)size scale:(CGFloat)scale fromURL:(NSURL*)url withResults:( void (^) ( UIImage* image, NSError* error ) )results
{
    NSAssert (NO, @"missing subclass implementation");
}

- (BOOL) hasCachedImageAtIndex:(NSUInteger)i
{
    return NO;
}

- (void) clearCache
{
    NSAssert (NO, @"missing subclass implementation");
}

- (void) clearMemoryCache
{
    NSAssert (NO, @"missing subclass implementation");
}

- (void) removeAllImages
{
    [self.imageData removeAllObjects];
}

// Given a full size image on disk, get an image of a specific size,
//  usually a small thumbnail.
// This algorithm is performance sensitive and core to the project. We potentially use it
//  while scrolling collection views.
+ (UIImage*) imageWithContentsOfFile:(NSString*)path size:(CGSize)size scale:(CGFloat)scale
{
    UIImage* result = nil;
    
    // Testing on large images (~ 2300 x 1700) on iPhone 6S+:
    
    //NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    // OPTION 1:
    //  load entire image from disk, create shrunken + cropped version
    //result = [[UIImage alloc] initWithContentsOfFile:path];
    //result = [self.class imageWithImage:result maximumSize:size scale:scale opaque:YES];
    
    // OPTION 2
    // Using CGImageSource to generate thumbnail directly from a file stream:
    //  Time ~ 0.05sec for small thumbnails (grid view, portrait), 0.15 for large (list view, landscape).
    //  Time varies widely per image (.015 - .25 sec for large)
    //  This only creates square images though. So to preserve memory we should
    //  crop the results.
    int thumbnailPixelSize = MAX (size.width, size.height) * scale;
    result = [self.class thumbnailWithContentsOfFile:path size:thumbnailPixelSize scale:scale];
    result = [self.class imageWithImage:result croppedToFitSize:size scale:scale opaque:YES];
    
    // OPTION 3: use PHImageManager. This option is not developed yet. #2 works very well
    //  though, so PHImageManager has a high bar to hurdle over.
    
    //NSLog(@"GENERATING %d x %d @ %dx THUMBNAIL TOOK %f SECONDS", (int)size.width, (int)size.height, (int)scale, [NSDate timeIntervalSinceReferenceDate] - start);
    
    return result;
}

// Core Graphics algorithm for cropping images
+ (UIImage*) imageWithImage:(UIImage*)image croppedToFitSize:(CGSize)size scale:(CGFloat)scale opaque:(BOOL)opaque
{
    CGSize imagePixelSize = CGSizeMake( image.size.width * image.scale, image.size.height * image.scale);
    CGSize croppedPixelSize = CGSizeMake ( size.width * scale, size.height * scale );
    if (CGSizeEqualToSize( imagePixelSize, croppedPixelSize) ) return image;

    UIImage* croppedImage = image;
    UIImageOrientation orientation = UIImageOrientationUp;
    CGRect cropRect = CGRectMake(0, 0, imagePixelSize.width, imagePixelSize.height);
    
    CGFloat imageAspectRatio = imagePixelSize.width / imagePixelSize.height;
    CGFloat targetAspectRatio = croppedPixelSize.width / croppedPixelSize.height;
    if ( targetAspectRatio > imageAspectRatio )
    {
        // target image has wider aspect ratio. Keep full image width, but crop the height
        CGFloat croppedHeight = imagePixelSize.height * (imageAspectRatio / targetAspectRatio);
        cropRect.origin.y = .5 * ( cropRect.size.height - croppedHeight );
        cropRect.size.height = croppedHeight;
        //NSLog(@"cropped image height: %@", NSStringFromCGRect(cropRect));
    }
    else if ( targetAspectRatio < imageAspectRatio )
    {
        // target image has taller aspect ratio. Keep full image height, but crop the width
        CGFloat croppedWidth = imagePixelSize.width * ( targetAspectRatio / imageAspectRatio );
        cropRect.origin.x = .5 * ( cropRect.size.width - croppedWidth );
        cropRect.size.width = croppedWidth;
        //NSLog(@"cropped image width: %@", NSStringFromCGRect(cropRect));
    }
    cropRect = CGRectIntegral(cropRect);
    if ( imageAspectRatio != targetAspectRatio )
    {
        //NSLog(@"Cropping %@ area out of %d x %d image", NSStringFromCGRect(cropRect), (int)imagePixelSize.width, (int)imagePixelSize.height);
        CGImageRef croppedImageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
        croppedImage = [[UIImage alloc] initWithCGImage:croppedImageRef scale:scale orientation:orientation];
        CGImageRelease(croppedImageRef);
    }
    
    return croppedImage;
}

// Core Graphics algorithm for downscaling
+ (UIImage*) imageWithImage:(UIImage*)image downscaledToSize:(CGSize)size scale:(CGFloat)scale opaque:(BOOL)opaque
{
    CGSize imagePixelSize = CGSizeMake( image.size.width * image.scale, image.size.height * image.scale);
    CGSize scaledPixelSize = CGSizeMake ( size.width * scale, size.height * scale );

    UIImage* downscaledImage = image;

    if ( scaledPixelSize.width < imagePixelSize.width || scaledPixelSize.height < imagePixelSize.height )   // never make images larger, only smaller
    {
        // need to convert to point size instead of pixel size so that
        // UIGraphicsetImageFromCurrentImageContext will return an image
        // matching the passed in scale and point size
        UIGraphicsBeginImageContextWithOptions( size, opaque, scale );
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // convert from UIKit to Core Graphics coordinates
        CGContextTranslateCTM(context, 0, size.height);
        CGContextScaleCTM(context, 1, -1);
        
        CGRect bounds = CGRectMake(0, 0, size.width, size.height);
        CGContextDrawImage( context, bounds, image.CGImage );
        downscaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return downscaledImage;
}

// Helper method combining cropping and downscaling
+ (UIImage*) imageWithImage:(UIImage*)image maximumSize:(CGSize)size scale:(CGFloat)scale opaque:(BOOL)opaque
{
    UIImage* cropped = [self.class imageWithImage:image croppedToFitSize:size scale:scale opaque:opaque];
    UIImage* croppedAndScaled = [self.class imageWithImage:cropped downscaledToSize:size scale:scale opaque:opaque];
    return croppedAndScaled;
}

// Alternate optimized downscaling algorithm that generates a square thumbnail
+ (UIImage*) thumbnailWithContentsOfFile:(NSString*)path size:(CGFloat)size scale:(CGFloat)scale
{
     CGImageRef        thumbnailImage = NULL;
     CGImageSourceRef  imageSource;
     
     // Create an image source from NSData; no options.
     imageSource = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
     
     // Make sure the image source exists before continuing.
     if (imageSource == NULL){
     fprintf(stderr, "Image source is NULL.");
     return  NULL;
     }
     
     NSDictionary* options = @
     {
     (NSString*)kCGImageSourceCreateThumbnailWithTransform:@YES,
     (NSString*)kCGImageSourceCreateThumbnailFromImageIfAbsent:@YES,
     (NSString*)kCGImageSourceThumbnailMaxPixelSize:@(size)
     };
     // Create the thumbnail image using the specified options.
     thumbnailImage = CGImageSourceCreateThumbnailAtIndex( imageSource, 0,(CFDictionaryRef)options );
     
     // Make sure the thumbnail image exists before continuing.
     if (thumbnailImage == NULL)
     {
         fprintf(stderr, "Thumbnail image not created from image source.");
         return NULL;
     }
     
     // make sure resulting image has the correct scale and orientation
     UIImageOrientation orientation = UIImageOrientationUp;
     CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
     if(imageProperties)
     {
         //CFShow(dict);
         NSDictionary* nsImageProperties = (NSDictionary*)CFBridgingRelease(imageProperties);
         id orientationObject = nsImageProperties[@"Orientation"];
         if ( orientationObject != nil )
         {
             orientation = [orientationObject integerValue];
         }
     }
     
     UIImage* result = [[UIImage alloc] initWithCGImage:thumbnailImage scale:scale orientation:orientation];
     
     CFRelease(imageSource);
     CGImageRelease(thumbnailImage);
    
    return result;
}

@end


@interface ImageTestDataProvider()
// quick + easy simulated disk cache for image downloads. Just remember all the images we successfully
//  'downloaded' so we don't need to 'download' them again.
@property (strong, nonatomic) NSMutableSet<NSURL*>* downloadedImageURLs;
@end

@implementation ImageTestDataProvider

- (instancetype) init
{
    self = [super init];
    _minimumDelay = 0;
    _maximumDelay = 1;
    self.downloadedImageURLs = [NSMutableSet new];
    return self;
}

- (void) fetchDataWithResults:( void (^) (NSUInteger count, NSError* error) )results
{
    [self assertHasRootFolder];
    __weak __typeof(self) welf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [welf randomDelay];
        [welf loadImagesFromDirectory:welf.rootFolder];
        dispatch_async (dispatch_get_main_queue(), ^{
            results ( welf.imageData.count, nil );
        });
    });
}

// Simulated network behavior:
//
// On first load, add a random delay before loading a file from disk. This simulates a network download.
//
// After initial load, load directly from disk.
//
// Always load asynchronously, even if loading directly from disk. Disk access is fast (~0.1sec),
//  but not fast enough to use on the foreground thread while scrolling a UI quickly. Disk access should
//  be fast enough so that there won't be any visible placeholder images while scrolling at a normal speed.

- (void) fetchImageAtIndex:(NSUInteger)i size:(CGSize)size scale:(CGFloat)scale fromURL:(NSURL*)url withResults:( void (^) ( UIImage* image, NSError* error ) )results
{
    //NSLog( @"FETCHING IMAGE: .../%@ (%d x %d @ %dx)", url.lastPathComponent, (int)size.width, (int)size.height, (int)scale );
    
    // thread safety policy for image data:
    //  1. do all modifications to image data on the foreground thread to prevent contention
    //  2. load image metadata for the specified index before doing any
    //     background work. This protects us against the image data array rearranging while
    //     we are doing background work.
    NSMutableDictionary* thisImageData = self.imageData[i];
    NSString* path = thisImageData[kImageDataKeyFilePath];
    BOOL hasPreviousDownload = [self.downloadedImageURLs containsObject:url];
    
    [thisImageData removeObjectForKey:kImageDataKeySourceURL];
    [thisImageData removeObjectForKey:kImageDataKeyRequestedSize];
    
    NSAssert (url != nil, @"Attempt to fetch image without providing url. Bad developer!" );
    
    [self assertHasRootFolder];
    __weak __typeof(self) welf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // simulate network delay on first downloads
        if ( !hasPreviousDownload )
        {
            //NSLog(@"Simulating download for .../%@", url.lastPathComponent);
            [welf randomDelay];
        }
        
        // get properly sized + cropped image from disk
        UIImage* image = nil;
        if (path != nil)
        {
            image = [welf.class imageWithContentsOfFile:path size:size scale:scale];
        }

        // save results (on foreground thread to prevent thread contention)
        dispatch_async (dispatch_get_main_queue(), ^{
            
            //NSLog(@"finished fetching .../%@", url.lastPathComponent);
            if (url != nil)
            {
                [self.downloadedImageURLs addObject:url];
                thisImageData[kImageDataKeySourceURL] = url;
            }
            thisImageData[kImageDataKeyRequestedSize] = [NSValue valueWithCGSize:size];

            if (!image) NSLog(@"WARNING: missing image for url %@", url);
            
            results ( image, nil );
        });
    });
}

- (void) assertHasRootFolder
{
    NSAssert ( self.rootFolder != nil, @"must configure a root folder before using test image provider" );
}

- (void) randomDelay
{
    if (_maximumDelay > 0)
    {
        CGFloat zeroToOne = rand() / (CGFloat)RAND_MAX;
        NSTimeInterval delay = _minimumDelay + zeroToOne * (_maximumDelay - _minimumDelay);
        [NSThread sleepForTimeInterval:delay];
    }
}

#pragma mark - caching

- (BOOL) hasCachedImageAtIndex:(NSUInteger)i
{
    NSURL* downloadURL = [self dataForImageAtIndex:i][kImageDataKeySourceURL];
    return [self.downloadedImageURLs containsObject:downloadURL];
}

- (void) clearCache
{
    // clear memory cache
    [self clearMemoryCache];
    
    // clear disk cache (simulated)
    [self clearDiskCache];
}

- (void) clearMemoryCache
{
    // not implemented yet.
    // Wanted an in-memory disk cache for silky smooth fast scrolling. But this is
    // difficult to do without accidentally getting the wrong size image or
    // using too much memory.
}

- (void) clearDiskCache
{
    [self.downloadedImageURLs removeAllObjects];
    for (NSMutableDictionary* metadata in self.imageData)
    {
        [metadata removeObjectForKey:kImageDataKeySourceURL];
        [metadata removeObjectForKey:kImageDataKeyRequestedSize];
    }
}

- (void) removeAllImages
{
    [super removeAllImages];
    [self.downloadedImageURLs removeAllObjects];
}

- (UIImage*) imageAtIndex:(NSUInteger)i
{
    // we shouldn't access the disk in this method because
    //  it's too slow for smooth real time scrolling.

    // keeping an in memory cache would be useful, but is
    // difficult to do without getting the wrong image size or
    // using too much memory.
    
    // instead, let's always force a fetch and bridge the resulting UX gap
    // using animations.
    
    return nil;
}

@end
