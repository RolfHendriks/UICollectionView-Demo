//
//  RHGridCollectionView.m
//  CollectionViewDemo
//
//  Created by Rolf Hendriks on 6/21/17.
//  Copyright © 2017 Rolf Hendriks. All rights reserved.
//

#import "RHGridCollectionView.h"

@interface RHGridCollectionView()
@property (readonly, nonatomic) UICollectionViewFlowLayout* flowLayout;
@property (assign, nonatomic) UIEdgeInsets margins;

// configuration options for flexible cells that update automatically on autorotation / size change:
@property (assign, nonatomic) BOOL shouldExpandCells;
@property (assign, nonatomic) NSUInteger explicitColumnCount;

@property (strong, nonatomic) NSIndexPath* firstVisibleIndexPath;

@end

@implementation RHGridCollectionView

- (UICollectionViewFlowLayout*) flowLayout
{
    UICollectionViewFlowLayout* result = (UICollectionViewFlowLayout*)self.collectionViewLayout;
    NSAssert ([result isKindOfClass:UICollectionViewFlowLayout.class], @"Expected flow layout for grid collection view");
    return result;
}

// layout update mechanism:
//
// want to prevent having to recompute all layout properties any time a single property changes.
// layoutSubviews + setNeedsLayout is the usual way to batch updates in such a situation.
// However, with UICollectionView setNeedsLayout triggers a reload of all cells, which we don't want.
//
// So instead, we update the entire layout on any layout change, but design the API so that this will
// only happen once or twice. Also keep in mind we are leveraging -invalidateLayout, so the collection
// view will not actually rearrange cells twice. The only redundancy is that we could recompute the
// underlying flow layout properties more than once.
//
- (void) setNeedsUpdate
{
    if (self.shouldPreserveFirstVisibleCell && !self.firstVisibleIndexPath)
    {
        self.firstVisibleIndexPath = [self findFirstVisibleIndexPath];
    }
    [self updateLayout];
}

- (void) updateLayout
{
    BOOL isInitialized = !CGSizeEqualToSize(self.preferredCellSize, CGSizeZero);
    if (!isInitialized) return; // this happens when the view frame is set before we configured any layout parameters.
    
    // first let's translate basic properties to the underlying FlowLayout:
    UICollectionViewFlowLayout* layout = [self flowLayout];
    
    CGFloat xMargin = self.margins.left;
    CGFloat viewWidth = self.bounds.size.width;
    CGSize cellSize = [self actualCellSize];

    BOOL flexibleMargins = !self.shouldExpandCells;
    if (flexibleMargins)
    {
        NSUInteger columnCount = [self columnCount];
        if (columnCount > 0)
        {
            // use flexible horizontal margins, fixed spacing + cell size
            CGFloat contentWidth = cellSize.width * columnCount + (columnCount-1) * self.spacing.x;
            xMargin =  0.5 * ( viewWidth - contentWidth );
        }
    }
    layout.sectionInset = UIEdgeInsetsMake(self.margins.top, xMargin, self.margins.bottom, xMargin);
    layout.minimumInteritemSpacing = self.spacing.x;
    layout.minimumLineSpacing = self.spacing.y;
    layout.itemSize = cellSize;
    
    if (layout.itemSize.width <= 0 && layout.itemSize.height <= 0)
    {
        NSLog(@"WARNING: found invalid grid layout");
    }
    
    // Causes UICollectionView to change the position + size of existing cells, but not
    //  regenerate new cells. This is exactly what we want from a performance perspective.
    [layout invalidateLayout];
    
    
    // Optional: preserve the topmost visible cell
    if ( self.shouldPreserveFirstVisibleCell && self.firstVisibleIndexPath != nil )
    {
        CGFloat newOffset = [self scrollOffsetForIndexPath:self.firstVisibleIndexPath];
        newOffset = [self contentOffsetForScrollOffset:newOffset];
        self.contentOffset = CGPointMake(self.contentOffset.x, newOffset);
        self.firstVisibleIndexPath = nil; // should only need to make this adjustment once. Plus, keeping firstVisibleIndexPath around is misleading because it will be out of date after scrolling.
    }
}

#pragma mark - properties

- (void) setMargins:(UIEdgeInsets)margins spacing:(CGPoint)spacing preferredCellSize:(CGSize)preferredCellSize
{
    NSAssert ( ABS( margins.left - margins.right ) < 0.001, @"Variable horizontal grid margins are not supported."); // enforce consistent horizontal margins, but leave some slack for rounding errors
    _margins = margins;
    _spacing = spacing;
    _preferredCellSize = preferredCellSize;
    [self setNeedsUpdate];
}

- (void) configureForFixedCellSize
{
    self.explicitColumnCount = 0;
    self.shouldExpandCells = NO;
    [self setNeedsUpdate];
}

- (void) configureForFlexibleCellSize
{
    self.explicitColumnCount = 0;
    self.shouldExpandCells = YES;
    [self setNeedsUpdate];
}

- (void) configureForFixedColumnCount:(NSUInteger)columnCount
{
    self.explicitColumnCount = columnCount;
    self.shouldExpandCells = YES;   // ignored for fixed column layouts, but setting anyway to express intent
    [self setNeedsUpdate];
}

- (void) setShouldMaintainPreferredAspectRatio:(BOOL)shouldMaintainPreferredAspectRatio
{
    if (_shouldMaintainPreferredAspectRatio != shouldMaintainPreferredAspectRatio)
    {
        _shouldMaintainPreferredAspectRatio = shouldMaintainPreferredAspectRatio;
        if ( self.shouldExpandCells )
        {
            [self setNeedsUpdate];
        }
    }
}
- (CGSize) actualCellSize
{
    if (self.shouldExpandCells)
    {
        return [self cellSizeWithMinimumCellSize:self.preferredCellSize fixedAspectRatio:self.shouldMaintainPreferredAspectRatio];
    }
    return self.preferredCellSize;
}

#pragma mark - layout utils

- ( NSUInteger ) columnCountWithWidth:(CGFloat)width cellWidth:(CGFloat)cellWidth margin:(CGFloat)margin spacing:(CGFloat)spacing
{
    // fixed column layout:
    if ( self.explicitColumnCount > 0 ) return self.explicitColumnCount;
    
    // flexible #columns based on cell size:
    NSUInteger result = 1;
    CGFloat widthForOneColumn = 2*margin + cellWidth;
    if (width > widthForOneColumn)
    {
        CGFloat widthForExtraColumns = width - widthForOneColumn;
        CGFloat fColumnCount = 1 + widthForExtraColumns / (cellWidth + spacing);
        result = (NSUInteger) floor (fColumnCount);
    }
    
    // edge case: let's prevent zero column layouts - they complicate logic and don't make any sense.
    //  The above logic should ensure that column count is 1 even if we don't have enough space for a single cell.
    NSAssert (result > 0, @"found a zero column layout. This should never happen.");
    
    return result;
}

- (NSUInteger) columnCountWithCellWidth:(CGFloat)cellWidth margin:(CGFloat)margin spacing:(CGFloat)spacing
{
    return [self columnCountWithWidth:self.bounds.size.width cellWidth:cellWidth margin:margin spacing:spacing];
}

- (NSUInteger) columnCount
{
    return [self columnCountWithCellWidth:self.preferredCellSize.width margin:self.margins.left spacing:self.spacing.x];
}

- (CGSize) cellSizeWithWidth:(CGFloat)width minimumCellSize:(CGSize)minimumSize fixedAspectRatio:(BOOL)fixedAspectRatio
{
    NSAssert ( minimumSize.height > 0, @"Missing minimum cell height" );
    NSAssert ( minimumSize.width > 0, @"Missing minimum cell width" );
    
    CGFloat margin = self.margins.left;
    CGFloat spacing = self.spacing.x;
    NSUInteger columnCount = [self columnCountWithWidth:width cellWidth:minimumSize.width margin:margin spacing:spacing];
    if (columnCount == 0) return CGSizeZero;    // should never happen
    
    CGFloat cellWidth = ( width - 2*margin - (columnCount-1)*spacing ) / columnCount;
    CGFloat cellHeight = minimumSize.height;
    if ( fixedAspectRatio )
    {
        CGFloat aspectRatio = minimumSize.width / minimumSize.height;
        cellHeight = cellWidth / aspectRatio;
    }
    
    return CGSizeMake(cellWidth, cellHeight);
}

- (CGSize) cellSizeWithMinimumCellSize:(CGSize)minimumCellSize fixedAspectRatio:(BOOL)fixedAspectRatio
{
    return [self cellSizeWithWidth:self.bounds.size.width minimumCellSize:minimumCellSize fixedAspectRatio:fixedAspectRatio];
}

#pragma mark - size change

- (void) setFrame:(CGRect)frame
{
    BOOL sizeChanged = !CGSizeEqualToSize(frame.size, self.frame.size);
    if (sizeChanged && self.shouldPreserveFirstVisibleCell)
    {
        // Setting a new frame changes the topMost cell. So if we want to preserve the topmost
        // cell, we need to find the value before changing the frame:
        self.firstVisibleIndexPath = [self findFirstVisibleIndexPath];
    }
    [super setFrame:frame];
    if (sizeChanged )
    {
        // need to re-sync the grid layout with the underlying flow layout
        [self setNeedsUpdate];
    }
}

- (void) reloadData
{
    [super reloadData];
}

- (void) reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
    [super reloadItemsAtIndexPaths:indexPaths];
}

/* 
 SCROLLING CUSTOMIZATION:
 - Snap to an exact multiple of a row height if dragging up or down
 - maintain current photo index if changing interface orientation, and snap to multiple of row height
*/

- (CGFloat) offsetThatFits:(CGFloat)offset fromBottom:(BOOL)bottom
{
    CGFloat result = offset;
    CGFloat cellHeight = [self actualCellSize].height;
    CGFloat rowHeight = cellHeight + self.spacing.y;
    NSInteger itemCount = [self numberOfItemsInSection:0];
    NSInteger columnCount = [self columnCount];
    NSInteger rowCount = itemCount / columnCount;
    if ( itemCount % columnCount > 0 ) ++ rowCount;
    
    // ignore overlapping top bars when aligning rows.
    // Scrolling to top has a scroll offset of -64 with a translucent top bar.
    CGFloat offsetRelativeToTopLayoutGuide = offset + self.contentInset.top;
    
    // offset that snaps to top of view:
    if (!bottom)
    {
        CGFloat topMargin = self.margins.top;
        CGFloat offsetInRows = ( offsetRelativeToTopLayoutGuide - topMargin ) / rowHeight;
        offsetInRows = round(offsetInRows);
        if ( offsetInRows < 0 ) offsetInRows = 0;
        else if ( offsetInRows >= rowCount ) offsetInRows = rowCount - 1;
        
        CGFloat y = topMargin + offsetInRows * rowHeight; // offset so that top of target row is at the top of the scroll view
        y -= offsetInRows == 0 ? topMargin : self.spacing.y; // include vertical margin
        y -= self.contentInset.top;
        result = y;
    }
    // offset that snaps to bottom of view:
    else
    {
        // do all math in terms of scroll offset from the bottom of the view
        CGFloat bottomMargin = self.margins.bottom;
        CGFloat maximumOffset = self.contentSize.height - self.bounds.size.height;
        CGFloat offsetFromBottom = maximumOffset - offsetRelativeToTopLayoutGuide;
        CGFloat offsetInRows = ( offsetFromBottom - bottomMargin ) / rowHeight;
        offsetInRows = round(offsetInRows);
        if ( offsetInRows < 0 ) offsetInRows = 0;
        else if ( offsetInRows >= rowCount ) offsetInRows = rowCount - 1;
        
        offsetFromBottom = bottomMargin + offsetInRows * rowHeight;
        offsetFromBottom -= offsetInRows == 0 ? bottomMargin : self.spacing.y;
        offsetFromBottom -= self.contentInset.bottom;
        
        // convert bottom offset back into offset from top
        result = maximumOffset - offsetFromBottom;
    }
    
    return result;
}

- (NSIndexPath*) findFirstVisibleIndexPath
{
    NSArray<NSIndexPath*>* visibleIndexPaths = self.indexPathsForVisibleItems;
    NSIndexPath* result = nil;
    for ( NSIndexPath* indexPath in visibleIndexPaths )
    {
        if (result == nil || (indexPath.section <= result.section && indexPath.row < result.row ) )
        {
            // create a user-facing definition of what a 'visible' cell is. To iOS, any cell that is partially
            // or fully onscreen is visible. This includes, for example, a cell that is behind the navigation
            // bar and almost all the way off the top edge of the screen.
            
            // to us, let's say a 'visible' cell is one that is less than halfway obscured by the navigation
            // bar or top edge of the screen:
            CGRect frame = [self layoutAttributesForItemAtIndexPath:indexPath].frame;
            CGFloat topLayoutGuidePosition = self.contentOffset.y + self.contentInset.top;
            if (CGRectGetMidY(frame) >= topLayoutGuidePosition)
            {
                result = indexPath;
            }
        }
    }
    return result;
}

- (CGFloat) scrollOffsetForIndexPath:(NSIndexPath*)indexPath
{
    UICollectionViewLayoutAttributes* layout = [self layoutAttributesForItemAtIndexPath:indexPath];
    CGFloat result = layout.frame.origin.y; // scrolling so that item's top is at the grid view's top border
    result -= indexPath.item == 0 ? self.margins.top : self.spacing.y; // leave room for margin / spacing
    return result;
}

// With a translucent top bar, scrolling to top has a y offset of
// -64px, not zero. To get around this, we define scroll offsets to
// do our math as if there were no bar. We then convert to content
// offsets, which factor in the overlapping bar.
- (CGFloat) contentOffsetForScrollOffset:(CGFloat)scrollOffset
{
    return scrollOffset - self.contentInset.top;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    // judgement call: don't snap to nearest cell unless scroll view is going to decelerate
    if (velocity.y == 0) return;
    
    // don't override behavior if scrolling past endpoints - we want to keep
    //  iOS's bounce behavior.
    CGFloat maximumContentOffset = scrollView.contentSize.height - scrollView.bounds.size.height;
    
    if ( targetContentOffset != nil && maximumContentOffset > 0 && targetContentOffset->y > 0 && targetContentOffset->y < maximumContentOffset )
    {
        // indexPathForItemAtPoint: combined with layoutAttributesForItemAtIndexPath
        // seems like a good way to query for the correct target offset, but does not
        // work because indexPathForItemAtPoint: returns nil. We could likely fix this by
        // defining a UICollectionViewLayout subclass for grid layouts, but this seems
        // like overkill. Instead, let's compute the target offset manually:
        CGFloat y = [self offsetThatFits:targetContentOffset->y fromBottom:NO];
        targetContentOffset->y = y;
    }
}

@end
