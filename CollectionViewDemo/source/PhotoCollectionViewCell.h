//
//  PhotoCollectionViewCell.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (void) setImage:(UIImage*)image;
- (void) setTitle:(NSString*)title;

@property (strong, nonatomic) NSURL* downloadURL;
@property (assign, nonatomic) BOOL needsDownload;

- (void) setImageAnimated:(UIImage*)image;

@end

@interface PhotoCollectionViewCellWide : PhotoCollectionViewCell
@end
