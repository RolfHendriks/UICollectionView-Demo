//
//  RHParallaxScroller.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/18/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 Implements parallax scrolling for table view cells or collection 
 view cells (or possibly any other view).
 
 Implemented as a model class instead of a view subclass so that 
 parallax can easily be applied to collection views, table views, 
 or any other views without any refactoring.
 
 RHParallaxScroller requires  a view with a separate content subview that
 takes up the entire size of the parent view and use autoresizingMasks.
 */
 

@interface RHParallaxScroller : NSObject

/**
 Apply parallax effect to a view. This should be called on scrollViewDidScroll, and
 when originally adding a view made for parallax (ex: cellForRowAtIndexPath).
 @param view the contents to which to apply parallax. Contents will exceed a view's bounds and are
    assumed to be laid out using autoresizing masks.
 @param superview the table view cell, collection view cell, or other container that maintains a fixed size 
    but changes position during scrolling.
 @param scrollView the scrollView that contains the content view
 @param maximumParallax the amount of pixels of parallax offset when the content view is at the far top or bottom screen edge.
 */
+ (void) updateContentView:(UIView*)view  inView:(UIView*)superview withScroll:(UIScrollView*)scrollView maximumParallax:(CGFloat)maximumParallax;

@end
