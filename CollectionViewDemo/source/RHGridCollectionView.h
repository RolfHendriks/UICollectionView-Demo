//
//  RHGridCollectionView.h
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/21/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Defines a simple API for a UICollectionView with a 2D grid layout.
 
 Unlike UICollectionView, horizontal alignment defaults to constant horizontal spacing with flexible
 left + right margins. UICollectionView uses constant left + right margins with flexible inter item margins instead, which looks poor with narrow horizontal margins.
 
 Also defines an API for flexible sized grid cells that take up 
    all space not used by margins and inter item spacing.
 */

@interface RHGridCollectionView : UICollectionView <UIScrollViewDelegate>


/**
 Configures the basic layout of a grid collection view. The resulting layout will have fixed cell size
 and spacing, flexible horizontal margins, and center horizontal alignment. This is different from 
 UICollectionView, which uses fixed horizontal margins and flexible horizontal spacing instead.
 @param margins the space between the collectionView frame and the outermost cells
 @param spacing the amount of space between columns and rows of cells
 @param preferredCellSize the size of each grid cell
 */
- (void) setMargins:(UIEdgeInsets)margins spacing:(CGPoint)spacing preferredCellSize:(CGSize)preferredCellSize;

/** 
 Computes the actual cell size that will be used. May be different from passed in cell size if
 grid was configured for flexible cell sizes.
 */
@property (readonly, nonatomic) CGSize actualCellSize;

@property (readonly, nonatomic) CGSize preferredCellSize;
@property (readonly, nonatomic) CGPoint spacing;
@property (readonly, nonatomic) UIEdgeInsets margins;

/**
 If set, the index of the first/topmost visible cell will remain the same when 
 layout changes. This generally matches user expectations and is recommended.
 */
@property (assign, nonatomic) BOOL shouldPreserveFirstVisibleCell;


// optionally use flexible cell sizes instead of the default layout:

/**
 Configures layout so that preferred cell size is the minimum cell size, and cells expand to take up 
 any slack and maintain constant margin and spacing. This is the recommended configuration.
 */
- (void) configureForFlexibleCellSize;

/**
 Configures layout for a fixed #columns. As a special case, can use a column count of 1 to implement a list layout.
 */
- (void) configureForFixedColumnCount:(NSUInteger)columnCount;

/** 
 For layouts with flexible cell sizes, enabling this flag ensures all cells have the same aspect ratio
 as the preferred cell size. If disabled, all cells have the same height as the preferred cell size.
 */
@property (assign, nonatomic) BOOL shouldMaintainPreferredAspectRatio;

/**
 Configures layout so that all cells have fixed size and spacing.
 
 This configuration is the default, and only needs to be set explicitly if reverting another
 configuration.
 */
- (void) configureForFixedCellSize;


/** 
 Ensures that scrolling automatically snaps to visible cells. Need to call this from within your 
 collectionViewDelegate. Since collection view delegates are also scroll view delegates, RHGridCollectionView cannot
 respond to scrolling events when its collectionViewDelegate is set.
*/
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset;

@end
