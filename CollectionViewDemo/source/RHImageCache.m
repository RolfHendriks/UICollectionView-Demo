//
//  RHImageCache.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/21/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "RHImageCache.h"

@implementation RHImageCache

- (instancetype) initWithMegabytes:(CGFloat)megabytes
{
    self = [super init];
    [self setMaximumSizeInBytes:[self.class bytesFromMegabytes:megabytes]];
    return self;
}

- (instancetype) init
{
    return [self initWithMegabytes:0];
}

- (void) setMaximumSizeInBytes:(NSUInteger)maximumSizeInBytes
{
    _maximumSizeInBytes = self.totalCostLimit = maximumSizeInBytes;
}

+ (NSUInteger) byteSizeEstimateForImage:(UIImage*)image
{
    CGFloat bytesPerPixel = 4; // hence the name byte size ESTIMATE
    return bytesPerPixel * image.size.width * image.size.height * image.scale * image.scale;
}

+ (NSUInteger) bytesFromMegabytes:(CGFloat)megs
{
    return (NSUInteger) (megs * 1024 * 1024);
}

- (UIImage*) getImageWithIdentifier:(NSString*)identifier
{
    return [self objectForKey:identifier];
}

- (void) putImage:(UIImage*)image withIdentifier:(NSString*)identifier
{
    if (image == nil || identifier == nil)
    {
        NSAssert (NO, @"Missing argument for putting image in image cache");
        return;
    }
    
    NSUInteger bytes = [self.class byteSizeEstimateForImage:image];
    [self setObject:image forKey:identifier cost:bytes];
}

- (void) removeImageWithIdentifier:(NSString*)identifier
{
    [self removeObjectForKey:identifier];
}

@end
