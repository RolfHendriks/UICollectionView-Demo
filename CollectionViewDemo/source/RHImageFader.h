//
//  RHImageFader.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/22/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 Animates in the color saturation of an image, beginning from 
 grayscale and ending at full saturation.
 */
@interface RHImageFader : NSObject

/**
 Fades in an image from grayscale. Returns the grayscale overlay that was added to the view.
 
 Currently only supports UIImageView, but could be modified to 
 accommodate any UIView if needed.
 
 Tip: set the opaque flag on the passed in view to improve performance
 */
+ (UIImageView*) animateWithView:(UIImageView*)imageView duration:(NSTimeInterval)duration completion:(void(^)())completion;

/**
 Cancels a previous animation so that the colored image is showing
 */
+ (void) cancelAnimationWithView:(UIView*)view;

/// Utility method to quickly get a grayscale version of a colored image
+ (UIImage*) grayScaleFromImage:(UIImage*)image opaque:(BOOL)opaque;

@end
