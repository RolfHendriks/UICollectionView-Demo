//
//  ImageProvider.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Image Metadata keys
#define kImageDataKeyFilePath    @"filePath"    // NSString representing locally cached image path
#define kImageDataKeySourceURL   @"url"     // NSURL of the origin of a completed image download
#define kImageDataKeyTitle       @"title"   // NSString for user facing title
#define kImageDataKeyRequestedSize @"requestedSize" // NSValue of NSSize storing the requested pixel size of the last download. Caution: actual image size may vary.

/**
    ImageProvider provides an array of images that may come from a local or remote source.
    We should generally expect that image count and metadata is available instantly, but images are
    nil until we finish loading them asynchronously.
 
    ImageProvider abstracts away details of fetching and caching large images 
    from a server. This allows us to test our functionality by simulating 
    a variety of server conditions.
 */

@interface ImageDataProvider : NSObject

- (NSUInteger) numberOfImages;
- (UIImage*) imageAtIndex:(NSUInteger)i;
- (NSMutableDictionary*) dataForImageAtIndex:(NSUInteger)i; // arbitrary image metadata. See above constants for a few exmaples, and feel free to add your own metadata.

/// Utility method for quickly (~.1sec) generating a thumbnail from disk
+ (UIImage*) imageWithContentsOfFile:(NSString*)path size:(CGSize)size scale:(CGFloat)scale;

// Can load an array of images from a local directory
- (void) loadImagesFromDirectory:(NSString*)directory;


// Block based API for fetching images from a remote source asynchronously:

/// Get all image metadata. After this, we should have an image count and complete image metatada, but no images.
- (void) fetchDataWithResults:( void (^) (NSUInteger imageCount, NSError* error) )results;

/**
 asynchronous loading of an image from a URL.
 @param i the index of the image to load
 @param size the desired image size, in device pixels.
 @param scale the current device scale factor
 @param url the URL from which to download the image.
 @param results the logic to execute when downloading finishes.
 */
- (void) fetchImageAtIndex:(NSUInteger)i size:(CGSize)size scale:(CGFloat)scale fromURL:(NSURL*)url withResults:( void (^) ( UIImage* image, NSError* error ) )results;

/**
 determine whether a fetch will result in a cache hit, in which 
 case retrieving the image should be reliably fast (~0.1sec).
 */
- (BOOL) hasCachedImageAtIndex:(NSUInteger)i;

// Memory management
- (void) clearCache;  // removes any cached images, forcing us to re-download all of them
- (void) clearMemoryCache;  // removes in-memory cache only, keeping disk cache for faster fetching.
- (void) removeAllImages; // sets images back to empty list, forcing us to re-download all image data and images. Mainly intended for testing.
// future: toggle use of disk cache and memory cache

@end


// test data provider usage:
//  * configure random simulated delays
//  * set root folder to load images from
//  * use asynchronous API to simulate loading images from a server
@interface ImageTestDataProvider : ImageDataProvider

@property (strong, nonatomic) NSString* rootFolder;
@property (assign, nonatomic) NSTimeInterval minimumDelay, maximumDelay;
// future: add error rate / utils for generating and testing download errors

@end
