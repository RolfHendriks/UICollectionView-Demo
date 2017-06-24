//
//  PhotoCollectionViewController.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/16/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCollectionViewController : UICollectionViewController

// Configure photos in a grid or list arrangement
- (void) configureForList;
- (void) configureForGrid;

/// force redownload of all images
- (void) reloadAll;
/// wipe out all image data + force redownload of images and data
- (void) clearAll;

@end
