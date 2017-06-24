//
//  RHParallaxScroller.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/18/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "RHParallaxScroller.h"

@implementation RHParallaxScroller

+ (void) updateContentView:(UIView*)contentView  inView:(UIView*)superview withScroll:(UIScrollView*)scrollView maximumParallax:(CGFloat)maximumParallax
{
    CGRect absoluteFrame = [scrollView convertRect:contentView.bounds fromView:contentView.superview];
    
    CGFloat scrollRelativeToView = CGRectGetMaxY(absoluteFrame) - scrollView.contentOffset.y; // parallax effect begins when target view's bottom is at the top of the screen
    CGFloat maximumScroll = scrollView.bounds.size.height + superview.bounds.size.height; // parallax effect ends when target view's top is at the bottom of the screen
    CGFloat normalizedScroll = scrollRelativeToView / maximumScroll; // from 0 = minimum parallax to 1 = maximum parallax

    if (normalizedScroll > 1) normalizedScroll = 1;
    else if (normalizedScroll < 0) normalizedScroll = 0;
    
    CGFloat imageY =  maximumParallax * ( 2*normalizedScroll - 1 ); // ranging from -maximumParallax to +maximumParallax
    
    contentView.frame = CGRectMake( 0, imageY, superview.bounds.size.width, superview.bounds.size.height + 2 * maximumParallax );
}

@end
