//
//  PhotoCollectionViewCell.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "PhotoCollectionViewCell.h"
//#import "RHImageFader.h"

#define kPhotoCellCrossfadeDuration 0.25
#define kPhotoCellColorFadeDuration 1.25

@interface PhotoCollectionViewCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) UIView* grayscaleOverlay;

@end

@implementation PhotoCollectionViewCell

- (void) setImage:(UIImage *)image { self.imageView.image = image; }
- (void) setTitle:(NSString *)title { self.titleLabel.text = title; }

- (void) setImageAnimated:(UIImage*)image
{
    // fade from black + white:
    /*
    self.imageView.image = image;
    self.imageView.opaque = YES; // performance optimization
    [RHImageFader animateWithView:self.imageView duration:kPhotoCellColorFadeDuration completion:nil];
    */
    
    // cross fade from existing image:
     CATransition* crossfade = [CATransition new];
     crossfade.duration = kPhotoCellCrossfadeDuration;
     [self.layer addAnimation:crossfade forKey:nil];
     self.image = image;
}

- (void) prepareForReuse
{
    //[RHImageFader cancelAnimationWithView:self.imageView];
    [super prepareForReuse];
}


@end

@implementation PhotoCollectionViewCellWide

- (void) setTitle:(NSString*)title
{
    self.titleLabel.text = nil;
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:title attributes:@
    {
        NSFontAttributeName:self.titleLabel.font,
        NSForegroundColorAttributeName:self.titleLabel.textColor,
        NSStrokeColorAttributeName:UIColor.blackColor,
        NSStrokeWidthAttributeName:@-4
    }];
}

@end
