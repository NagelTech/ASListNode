//
//  ASListNode.m
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//


#import <AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <ASAssert.h>

#import "ASListNode.h"

#import "ASListNodeScrollView.h"


@interface ASListNode () <UIScrollViewDelegate, ASListNodeScrollViewDelegate>

@property (nonatomic,readonly) ASListNodeScrollView *view;

@end


@implementation ASListNode {

    NSMutableDictionary *_cells;    // NSIndexPath -> ASCellNode
    NSIndexPath *_topIndexPath;
    NSMutableArray *_visibleCells;
    BOOL _virtualizedLeading;
    BOOL _virtualizedTrailing;
}


@dynamic view;


- (instancetype)init
{
    self = [super initWithViewBlock:^UIView *{
        ASListNodeScrollView *scrollView = [[ASListNodeScrollView alloc] init];
        scrollView.delegate = self;
        return scrollView;
    }];

    if (self) {
        _cells = [[NSMutableDictionary alloc] init];
        _topIndexPath = nil;
        _visibleCells = [[NSMutableArray alloc] init];
        _virtualizedLeading = YES;
        _virtualizedTrailing = YES;
    }

    return self;
}

- (id)initWithViewBlock:(ASDisplayNodeViewBlock)viewBlock
{
    ASDisplayNodeAssertNotSupported();
    return nil;
}

- (id)initWithLayerBlock:(ASDisplayNodeLayerBlock)viewBlock
{
    ASDisplayNodeAssertNotSupported();
    return nil;
}


#pragma mark - Properties


- (void)setLayerBacked:(BOOL)layerBacked
{
    ASDisplayNodeAssert(!layerBacked, @"ASListNode does not support layer-backing.");
}


- (void)setDelegate:(id<ASListNodeDelegate>)delegate {
    if (_delegate == delegate) {
        return ;
    }

    _delegate = delegate;

    [_visibleCells enumerateObjectsUsingBlock:^(ASCellNode *cell, NSUInteger idx, BOOL *stop) {
        [cell.view removeFromSuperview];
    }];

    [_visibleCells removeAllObjects];

    _topIndexPath = nil;

    [self setNeedsLayout];
}


#pragma mark - Content Size & virtualization


- (void)adjustContentOffset {
    ASCellNode *topCell = _visibleCells.firstObject;
    CGFloat yPos = topCell.frame.origin.y - self.view.contentOffset.y;  // position of cell on the screen

    CGFloat contentOffset = self.view.contentOffset.y;

    if ([self isFirstIndexPath:_topIndexPath]) {
        contentOffset = -yPos;
        _virtualizedLeading = NO;
    } else {
        contentOffset = self.view.bounds.size.height;
        if (contentOffset <= self.view.contentOffset.y) {
            contentOffset = self.view.contentOffset.y;
        } else {
            contentOffset += self.view.bounds.size.height;
        }
    }

    if (contentOffset != self.view.contentOffset.y) {
        CGFloat delta = contentOffset - self.view.contentOffset.y;

        NSLog(@"adjusting contentOffset by %f", delta);

        [_visibleCells enumerateObjectsUsingBlock:^(ASCellNode *cell, NSUInteger idx, BOOL *stop) {
            CGRect frame = cell.frame;
            frame.origin.y += delta;
            cell.frame = frame;
        }];

        self.view.contentOffset = (CGPoint){0, contentOffset};
        self.view.contentSize = (CGSize){self.bounds.size.width, self.view.contentSize.height + delta};
    }
}

- (void)recalculateContentSizeWithBottomIndexPath:(NSIndexPath *)bottomIndexPath {
    ASCellNode *bottomCell = _visibleCells.lastObject;
    CGFloat contentHeight = CGRectGetMaxY(bottomCell.frame);

    if ([self isLastIndexPath:bottomIndexPath]) {
        _virtualizedTrailing = NO;
        NSLog(@"_virtualizedTrailing = NO");
    } else {
        contentHeight += self.view.bounds.size.height;  // we maintain a minimum of one screen as buffer
        if (contentHeight <= self.view.contentSize.height) {    // don't shrink
            contentHeight = self.view.contentSize.height;
        } else {
            contentHeight += self.view.bounds.size.height;   // and a maximum size of 2 screens
        }
    }

    if ( self.view.contentSize.height != contentHeight) {
        NSLog(@"adjusting contentHeight by %f", self.view.contentSize.height - contentHeight);
        self.view.contentSize = (CGSize) {self.view.bounds.size.width, contentHeight};
    }
}


#pragma mark - Scroll To


- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ASListNodeScrollPosition)scrollPosition animated:(BOOL)animated
{
    // todo: if the item is already visible we just need to scroll to that position...
    // todo: how do we animate scrolling and animating when virtualization is involved...
    // todo: what if there is not enough content to fill the screen
    // todo: what if the position is invalid (ie put the top item at the bottom)

    // clear existing visible items...

    [_visibleCells enumerateObjectsUsingBlock:^(ASCellNode *cell, NSUInteger idx, BOOL *stop) {
        [cell.view removeFromSuperview];
    }];

    [_visibleCells removeAllObjects];

    // Find position on the screen we want...

    CGSize constrainedSize = (CGSize) {self.bounds.size.width, CGFLOAT_MAX};

    CGFloat yPos = 0;

    ASCellNode *cell = [self cellForItemAtIndexPath:indexPath];
    CGSize cellSize = [cell measure:constrainedSize];

    switch(scrollPosition) {
        default: // shouldn't happen
        case ASListNodePositionTop:
            yPos = 0;
            break;

        case ASListNodePositionMiddle:
            yPos = (self.view.bounds.size.height - cellSize.height) / 2;    // todo: pixel align
            break;

        case ASListNodePositionBottom:
            yPos = self.view.bounds.size.height - cellSize.height;
            break;
    }

    // figure out virtualization, content offset and size...

    _virtualizedLeading = ![self isFirstIndexPath:indexPath];
    _virtualizedTrailing = ![self isLastIndexPath:indexPath];

    CGFloat contentOffset = (_virtualizedLeading) ? self.view.bounds.size.height * 2 : 0;
    CGFloat contentSize = contentOffset + self.view.bounds.size.height + ((_virtualizedTrailing) ? self.view.bounds.size.height * 2 : 0);

    self.view.contentOffset = (CGPoint){0,contentOffset};
    self.view.contentSize = (CGSize){self.view.bounds.size.width, contentSize};

    // Add the anchor cell...

    cell.frame = (CGRect){.origin={0,contentOffset+yPos}, .size=cellSize};

    [self.view addSubview:cell.view];
    [_visibleCells addObject:cell];
    _topIndexPath = indexPath;

    // Now schedule a layout which will end up calling [self layoutVisibleItems];

    [self setNeedsLayout];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    NSIndexPath *indexPath = [self nextIndexPath:nil];

    if (!indexPath) {
        return ;    // no data
    }

    [self scrollToItemAtIndexPath:indexPath atScrollPosition:ASListNodePositionTop animated:animated];
}

- (void)scrollToEndAnimated:(BOOL)animated
{
    NSIndexPath *indexPath = [self prevIndexPath:nil];

    if (!indexPath) {
        return ;    // no data
    }

    [self scrollToItemAtIndexPath:indexPath atScrollPosition:ASListNodePositionBottom animated:animated];
}


#pragma mark - IndexPath helpers


- (NSIndexPath *)prevIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section;
    NSUInteger row;

    if (!indexPath) {
        section = [self numberOfSections];
        row = 0;
    } else {
        section = indexPath.section;
        row = indexPath.row;
    }

    while(row == 0) {
        if (section == 0) {
            return nil;
        }

        --section;
        row = [self numberOfItemsInSection:section];
    }

    return [NSIndexPath indexPathForRow:row-1 inSection:section];
}


- (NSIndexPath *)prevIndexPath:(NSIndexPath *)indexPath count:(int)count
{
    while (count-- > 0) {
        if (!(indexPath=[self prevIndexPath:indexPath])) {
            break;
        }
    }

    return indexPath;
}


- (BOOL)isFirstIndexPath:(NSIndexPath *)indexPath
{
    return indexPath && ![self prevIndexPath:indexPath];
}

- (NSIndexPath *)nextIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger section = (indexPath) ? indexPath.section : 0;
    NSInteger row = (indexPath) ? indexPath.row + 1 : 0;

    NSUInteger numberOfSections = [self numberOfSections];

    if (section >= numberOfSections) {
        return nil; // we are passed the last valid section
    }

    NSUInteger numberOfItemsInSection = [self numberOfItemsInSection:section];

    if ( row >= numberOfItemsInSection) {
        ++section;
        row = 0;

        // skip empty sections...

        while(section < numberOfSections) {
            numberOfItemsInSection = [self numberOfItemsInSection:section];

            if (numberOfItemsInSection > 0) {
                break;
            }

            ++section;
        }

        if (section >= numberOfSections) {
            return nil;
        }
    }

    return [NSIndexPath indexPathForRow:row inSection:section];
}

- (NSIndexPath *)nextIndexPath:(NSIndexPath *)indexPath count:(int)count
{
    while (count-- > 0) {
        if (!(indexPath=[self nextIndexPath:indexPath])) {
            break;
        }
    }

    return indexPath;
}

- (BOOL)isLastIndexPath:(NSIndexPath *)indexPath
{
    return indexPath && ![self nextIndexPath:indexPath];
}


#pragma mark - Data Access


- (NSUInteger)numberOfSections
{
    if ([self.dataSource respondsToSelector:@selector(numberOfSectionsInListNode:)]) {
        return [self.dataSource numberOfSectionsInListNode:self];
    } else {
        return 1;
    }
}

-(NSUInteger)numberOfItemsInSection:(NSUInteger)section
{
    return [self.dataSource listNode:self numberOfItemsInSection:section];
}

- (ASCellNode *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ASCellNode *cell = _cells[indexPath];

    if (!cell) {
        cell = [self.dataSource listNode:self cellForItemAtIndexPath:indexPath];
        if (cell) {
            _cells[indexPath] = cell;
        }
    }

    return cell;
}


#pragma mark - Layout


- (void)layoutVisibleCells
{
    NSIndexPath *bottomIndexPath = nil; // lazy initialized
    BOOL leadingChanged = NO;
    BOOL trailingChanged = NO;

    // If we don't have a topIndexPath, set it to the first visible cell...

    if (!_topIndexPath) {
        _topIndexPath = [self nextIndexPath:nil];

        if (!_topIndexPath) {
            return ;    // no valid cells to layout
        }
    }

    CGSize constrainedSize = (CGSize) {self.bounds.size.width, CGFLOAT_MAX};
    CGRect visibleArea = (CGRect) { .origin=self.view.contentOffset, .size=self.bounds.size };

    // remove now hidden leading cells from the list...
    // (note we always leave one cell so we maintain our context)

    while(_visibleCells.count > 1) {
        ASCellNode *cell = _visibleCells.firstObject;

        if (CGRectIntersectsRect(cell.frame, visibleArea)) {
            break;
        }

        NSLog(@"removing leading cell at %@", _topIndexPath);

        [_visibleCells removeObjectAtIndex:0];
        [cell.view removeFromSuperview];

        _topIndexPath = [self nextIndexPath:_topIndexPath];

        leadingChanged = YES;
    }

    // remove hidden trailing cells...

    while (_visibleCells.count > 1) {
        ASCellNode *cell = _visibleCells.lastObject;

        if (CGRectIntersectsRect(cell.frame, visibleArea)) {
            break;
        }

        if (!bottomIndexPath) { // only initialize this if it looks like we need it
            bottomIndexPath = [self nextIndexPath:_topIndexPath count:(int)_visibleCells.count - 1];
        }


        NSLog(@"removing trailing cell at %@", bottomIndexPath);

        [_visibleCells removeLastObject];
        [cell.view removeFromSuperview];
        bottomIndexPath = [self prevIndexPath:bottomIndexPath];

        trailingChanged = YES;
    }

    // stack items on the top if we have any...

    ASCellNode *topCell = _visibleCells.firstObject;

    while(topCell && topCell.frame.origin.y > visibleArea.origin.y) {
        NSIndexPath *indexPath = [self prevIndexPath:_topIndexPath];

        if (!indexPath) {
            break;
        }

        NSLog(@"adding leading cell at %@", indexPath);

        ASCellNode *cell = [self cellForItemAtIndexPath:indexPath];
        CGSize cellSize = [cell measure:constrainedSize];

        cell.frame = (CGRect) {.origin={0,topCell.frame.origin.y-cellSize.height}, .size=cellSize};
        [self.view addSubview:cell.view];
        [_visibleCells insertObject:cell atIndex:0];

        _topIndexPath = indexPath;

        topCell = cell;

        leadingChanged = YES;
    }

    // Now, stack items at the bottom until filled in...

    ASCellNode *bottomCell = _visibleCells.lastObject;
    CGFloat visibileMaxY = CGRectGetMaxY(visibleArea);

    while(!bottomCell || CGRectGetMaxY(bottomCell.frame) < visibileMaxY) {

        if (!bottomIndexPath) { // only initialize this if it looks like we need it
            bottomIndexPath = [self nextIndexPath:_topIndexPath count:(int)_visibleCells.count - 1];
        }

        NSIndexPath *indexPath = (bottomCell) ? [self nextIndexPath:bottomIndexPath] : bottomIndexPath;
        CGFloat yPos = (bottomCell) ? CGRectGetMaxY(bottomCell.frame) : visibleArea.origin.y;

        if (!indexPath) {
            break;
        }

        NSLog(@"adding trailing cell at %@", indexPath);

        ASCellNode *cell = [self cellForItemAtIndexPath:indexPath];
        CGSize cellSize = [cell measure:constrainedSize];

        cell.frame = (CGRect) {.origin={0,yPos}, .size=cellSize};
        [self.view addSubview:cell.view];
        [_visibleCells addObject:cell];

        bottomCell = cell;
        bottomIndexPath = indexPath;

        trailingChanged = YES;
    }

    // adjust the content size if needed...

    if (trailingChanged && _virtualizedTrailing) {
        [self recalculateContentSizeWithBottomIndexPath:bottomIndexPath];
    }

    if (leadingChanged && _virtualizedLeading) {
        [self adjustContentOffset];
    }
}


#pragma mark - ASDisplayNode


#pragma mark - ASListNodeScrollViewDelegate

- (void)listNodeScrollViewLayoutSubviews:(ASListNodeScrollView *)scrollView
{
    if (self.dataSource) {
        [self layoutVisibleCells];
    }
}

#pragma mark - UIScrollViewDelegate



@end
