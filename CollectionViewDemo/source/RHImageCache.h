//
//  RHImageCache.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/21/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 Implements an in-memory cache for downloaded images. May be expanded 
 to add disk-based caching abilities in the future.
 */
@interface RHImageCache : NSCache

- (instancetype) initWithMegabytes:(CGFloat)megabytes NS_DESIGNATED_INITIALIZER;

// get + set images based on unique ID
- (UIImage*) getImageWithIdentifier:(NSString*)identifier;
- (void) putImage:(UIImage*)image withIdentifier:(NSString*)identifier;
- (void) removeImageWithIdentifier:(NSString*)identifier;

// manage maximum cache size. If not set, cache will grow until app receives low memory warning.
@property (assign, nonatomic) NSUInteger maximumSizeInBytes;
+ (NSUInteger) byteSizeEstimateForImage:(UIImage*)image;
+ (NSUInteger) bytesFromMegabytes:(CGFloat)megs;

@end
