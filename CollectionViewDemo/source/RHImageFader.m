//
//  RHImageFader.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/22/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "RHImageFader.h"

#define kImageFaderOverlayViewTag -1

@implementation RHImageFader

+ (UIImageView*) animateWithView:(UIImageView*)imageView duration:(NSTimeInterval)duration completion:(void(^)())completion
{
    UIImage* grayscale = [self.class grayScaleFromImage:imageView.image opaque:imageView.opaque];
    UIImageView* overlay = [[UIImageView alloc] initWithImage:grayscale];
    overlay.tag = kImageFaderOverlayViewTag;
    overlay.frame = imageView.bounds;
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    overlay.contentMode = imageView.contentMode;
    [imageView addSubview:overlay];
    
    [UIView animateWithDuration:duration delay:0 options: UIViewAnimationOptionCurveEaseIn animations:^
    {
        overlay.alpha = 0;
    } completion:^(BOOL finished)
    {
        [overlay removeFromSuperview];
        if (completion) completion();
    }];
    
    return nil;
    return overlay;
}

+ (void) cancelAnimationWithView:(UIView*)view
{
    [[view viewWithTag:kImageFaderOverlayViewTag] removeFromSuperview];
}

+ (UIImage*) grayScaleFromImage:(UIImage*)image opaque:(BOOL)opaque
{
    // NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    CGSize size = image.size;
    
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    
    // Create bitmap content with current image size and grayscale colorspace
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = opaque ? 1 : 2;
    size_t bytesPerRow = bytesPerPixel * size.width * image.scale;
    CGContextRef context = CGBitmapContextCreate(nil, size.width, size.height, bitsPerComponent, bytesPerRow, colorSpace, opaque ? kCGImageAlphaNone : kCGImageAlphaPremultipliedLast);
    
    // create image from bitmap
    CGContextDrawImage(context, bounds, image.CGImage);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage* result = [[UIImage alloc] initWithCGImage:cgImage scale:image.scale orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGContextRelease(context);
    
    // performance results on iPhone 6S+ in Release mode.
    // Results are in photo pixels, not device pixels:
    //  ~ 5ms for 500px x 600px
    //  ~ 15ms for 2200px x 600px
    // NSLog(@"generating %d x %d @ %dx grayscale took %f seconds", (int)size.width, (int)size.height, (int)image.scale, [NSDate timeIntervalSinceReferenceDate] - start);
    
    return result;
}

@end
