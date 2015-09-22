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


const ASListNodeIndex ASListNodeIndexInvalid = -1;


@implementation ASListNodeOperation

- (instancetype)initWithType:(ASListNodeOperationType)type sourceIndex:(ASListNodeIndex)sourceIndex destIndex:(ASListNodeIndex)destIndex count:(NSInteger)count items:(NSArray *)items
{
    if ((self=[super init])) {
        _type = type;
        _sourceIndex = sourceIndex;
        _destIndex = destIndex;
        _count = count;
        _items = items;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self.class allocWithZone:zone] initWithType:_type sourceIndex:_sourceIndex destIndex:_destIndex count:_count items:_items];
}

+ (instancetype)insertAtIndex:(ASListNodeIndex)destIndex items:(NSArray *)items {
    return [[self alloc] initWithType:ASListNodeOperationTypeInsert sourceIndex:ASListNodeIndexInvalid destIndex:destIndex count:0 items:items];
}

+ (instancetype)deleteFromIndex:(ASListNodeIndex)sourceIndex count:(NSInteger)count {
    return [[self alloc] initWithType:ASListNodeOperationTypeDelete sourceIndex:sourceIndex destIndex:ASListNodeIndexInvalid count:count items:nil];
}

@end


@implementation ASListNodeBatch {
    NSMutableArray<ASListNodeOperation *> *_operations;
}

- (instancetype)init {
    if ((self=[super init])) {
        _operations = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addOperation:(ASListNodeOperation *)operation
{
    [_operations addObject:operation];
}

- (void)insertAtIndex:(ASListNodeIndex)destIndex items:(NSArray *)items {
    [self addOperation:[ASListNodeOperation insertAtIndex:destIndex items:items]];
}

- (void)deleteFromIndex:(ASListNodeIndex)sourceIndex count:(NSInteger)count {
    [self addOperation:[ASListNodeOperation deleteFromIndex:sourceIndex count:count]];
}

@end


@interface ASListNodeBatchInternal : NSObject

@property (nonatomic,readonly) NSArray<ASListNodeOperation *> *operations;

- (instancetype)initWithBatch:(ASListNodeBatch *)batch;

@end


@implementation ASListNodeBatchInternal

- (instancetype)initWithBatch:(ASListNodeBatch *)batch
{
    if ((self=[super init])) {
        _operations = batch.operations;
    }
    
    return self;
}

@end


@interface ASListNode () <UIScrollViewDelegate, ASListNodeScrollViewDelegate>

@property (nonatomic,readonly) ASListNodeScrollView *view;

@end


@implementation ASListNode {

    NSMutableArray *_items;
    NSMutableArray *_cells;         // always matches items
    ASListNodeIndex _topIndex;
    NSMutableArray *_visibleCells;
    BOOL _virtualizedLeading;
    BOOL _virtualizedTrailing;
    dispatch_queue_t _batchQueue;
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
        _items = [[NSMutableArray alloc] init];
        _cells = [[NSMutableArray alloc] init];
        _topIndex = ASListNodeIndexInvalid;
        _visibleCells = [[NSMutableArray alloc] init];
        _virtualizedLeading = YES;
        _virtualizedTrailing = YES;
        _batchQueue = dispatch_queue_create("ASListNodeBatch", DISPATCH_QUEUE_SERIAL);
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

    _topIndex = ASListNodeIndexInvalid;

    [self setNeedsLayout];
}


- (NSArray *)items
{
    return [_items copy];
}


- (void)setItems:(NSArray *)items
{
    
    // todo: can we maintain our top index when we do this?
    
    [_items removeAllObjects];
    [_cells removeAllObjects];
    [_visibleCells removeAllObjects];
    _topIndex = 0;
    
    [_items addObjectsFromArray:items];
}


#pragma mark - Content Size & virtualization


- (void)adjustContentOffset {
    ASCellNode *topCell = _visibleCells.firstObject;
    CGFloat yPos = topCell.frame.origin.y - self.view.contentOffset.y;  // position of cell on the screen

    CGFloat contentOffset = self.view.contentOffset.y;

    if (_topIndex == 0) {
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

- (void)recalculateContentSizeWithBottomIndex:(ASListNodeIndex)bottomIndex {
    ASCellNode *bottomCell = _visibleCells.lastObject;
    CGFloat contentHeight = CGRectGetMaxY(bottomCell.frame);

    if (bottomIndex == self.items.count-1) {
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


- (void)scrollToItemAtIndex:(ASListNodeIndex)index atScrollPosition:(ASListNodeScrollPosition)scrollPosition animated:(BOOL)animated
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

    ASCellNode *cell = [self cellForItemAtIndex:index];
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

    _virtualizedLeading = !(index == 0);
    _virtualizedTrailing = !(index == self.items.count-1);

    CGFloat contentOffset = (_virtualizedLeading) ? self.view.bounds.size.height * 2 : 0;
    CGFloat contentSize = contentOffset + self.view.bounds.size.height + ((_virtualizedTrailing) ? self.view.bounds.size.height * 2 : 0);

    self.view.contentOffset = (CGPoint){0,contentOffset};
    self.view.contentSize = (CGSize){self.view.bounds.size.width, contentSize};

    // Add the anchor cell...

    cell.frame = (CGRect){.origin={0,contentOffset+yPos}, .size=cellSize};

    [self.view addSubview:cell.view];
    [_visibleCells addObject:cell];
    _topIndex = index;

    // Now schedule a layout which will end up calling [self layoutVisibleItems];

    [self setNeedsLayout];
}

- (void)scrollToTopAnimated:(BOOL)animated
{
    [self scrollToItemAtIndex:0 atScrollPosition:ASListNodePositionTop animated:animated];
}

- (void)scrollToEndAnimated:(BOOL)animated
{
    [self scrollToItemAtIndex:self.items.count-1 atScrollPosition:ASListNodePositionBottom animated:animated];
}


#pragma mark - Data Access


- (ASCellNode *)cellForItemAtIndex:(ASListNodeIndex)index
{
    ASCellNode *cell = (index < _cells.count) ? _cells[index] : nil;
    
    if ((id)cell == [NSNull null]) {
        cell = nil;
    }

    if (!cell) {
        id item = _items[index];
        cell = [self.dataSource listNode:self cellForItem:item atIndex:index];
        ASDisplayNodeAssert(cell != nil, @"ASListNodeDataSource listNode:cellForItem:atIndex may not return nil");
        
        while(index > _cells.count) {
            [_cells addObject:[NSNull null]];
        }
        
        _cells[index] = cell;
    }

    return cell;
}


#pragma mark - Layout


- (void)layoutVisibleCells
{
    BOOL leadingChanged = NO;
    BOOL trailingChanged = NO;
    
    if (_items.count == 0) {
        // todo: maybe we need to remove any currently visible cells?
        return ;    // no items to layout
    }

    // If we don't have a topIndex, set it to the first cell...

    if (_topIndex == ASListNodeIndexInvalid) {
        _topIndex = 0;
    }
    
    ASListNodeIndex bottomIndex = _topIndex + _visibleCells.count - 1;

    CGSize constrainedSize = (CGSize) {self.bounds.size.width, CGFLOAT_MAX};
    CGRect visibleArea = (CGRect) { .origin=self.view.contentOffset, .size=self.bounds.size };

    // remove now hidden leading cells from the list...
    // (note we always leave one cell so we maintain our context)

    while(_visibleCells.count > 1) {
        ASCellNode *cell = _visibleCells.firstObject;

        if (CGRectIntersectsRect(cell.frame, visibleArea)) {
            break;
        }

        NSLog(@"removing leading cell at %zd", _topIndex);

        [_visibleCells removeObjectAtIndex:0];
        [cell.view removeFromSuperview];

        ++_topIndex;

        leadingChanged = YES;
    }

    // remove hidden trailing cells...

    while (_visibleCells.count > 1) {
        ASCellNode *cell = _visibleCells.lastObject;

        if (CGRectIntersectsRect(cell.frame, visibleArea)) {
            break;
        }

        NSLog(@"removing trailing cell at %zd", bottomIndex);

        [_visibleCells removeLastObject];
        [cell.view removeFromSuperview];
        --bottomIndex;

        trailingChanged = YES;
    }

    // stack items on the top if we have any...

    ASCellNode *topCell = _visibleCells.firstObject;

    while(topCell && topCell.frame.origin.y > visibleArea.origin.y && _topIndex > 0) {
        --_topIndex;

        NSLog(@"adding leading cell at %zd", +_topIndex);

        ASCellNode *cell = [self cellForItemAtIndex:_topIndex];
        CGSize cellSize = [cell measure:constrainedSize];

        cell.frame = (CGRect) {.origin={0,topCell.frame.origin.y-cellSize.height}, .size=cellSize};
        [self.view addSubview:cell.view];
        [_visibleCells insertObject:cell atIndex:0];

        topCell = cell;

        leadingChanged = YES;
    }

    // Now, stack items at the bottom until filled in...

    ASCellNode *bottomCell = _visibleCells.lastObject;
    CGFloat visibileMaxY = CGRectGetMaxY(visibleArea);

    while((bottomIndex < (ASListNodeIndex)_items.count-1) && (!bottomCell || CGRectGetMaxY(bottomCell.frame) < visibileMaxY)) {

        ASListNodeIndex index = bottomIndex+1;
        CGFloat yPos = (bottomCell) ? CGRectGetMaxY(bottomCell.frame) : visibleArea.origin.y;

        if (index < 0) {
            break;
        }

        NSLog(@"adding trailing cell at %zd", index);

        ASCellNode *cell = [self cellForItemAtIndex:index];
        CGSize cellSize = [cell measure:constrainedSize];

        cell.frame = (CGRect) {.origin={0,yPos}, .size=cellSize};
        [self.view addSubview:cell.view];
        [_visibleCells addObject:cell];

        bottomCell = cell;
        bottomIndex = index;

        trailingChanged = YES;
    }

    // adjust the content size if needed...

    if (trailingChanged && _virtualizedTrailing) {
        [self recalculateContentSizeWithBottomIndex:bottomIndex];
    }

    if (leadingChanged && _virtualizedLeading) {
        [self adjustContentOffset];
    }
}


#pragma mark - Batch support


- (void)executeInsertOperation:(ASListNodeOperation *)operation
{
   // First, make the updates on our underlying data structures...
    
    [operation.items enumerateObjectsUsingBlock:^(id  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSUInteger index = (NSUInteger)operation.destIndex + idx;
        
        [_items insertObject:item atIndex:index];
        [_cells insertObject:[NSNull null] atIndex:index];
    }];
    
    // todo: will this work when inserting at the start or end?
    // todo: what if the list fits on the screen?
    
    ASListNodeIndex firstIndex = operation.destIndex;
    NSInteger count = operation.items.count;
    
    if ( firstIndex <= _topIndex ) {  // we started before the current top of the visible area
        NSLog(@"inserting cells before visibleCells");
        if (!_virtualizedLeading) {
            _virtualizedLeading = YES;
            NSLog(@"virtualizing leading");
        }
        _topIndex += count;
    } else if (firstIndex > _topIndex + _visibleCells.count - 1) {  // we are inserting after the visible area
        NSLog(@"inserting cells after visibleCells");
        if (!_virtualizedTrailing) {
            _virtualizedTrailing = YES;
            NSLog(@"virtualizing trailing");
        }
    } else {    // we are insertig in the visible area
        
        NSLog(@"inserting into visibleCells");
        
        // todo: well, lots of work needs to be done here.
        // shift cells down, actually insert the new ones here
        // animate the whole process

        // remove all visible items after the firstIndex, so we will rebuild them...
        
        while (_visibleCells.count > firstIndex-_topIndex) {
            ASDisplayNode *cell = _visibleCells.lastObject;
            
            [cell.view removeFromSuperview];
            [_visibleCells removeLastObject];
        }
        
        if (!_virtualizedTrailing) {
            _virtualizedTrailing = YES;
            NSLog(@"virtualizing trailing");
        }
        
        [self layoutVisibleCells];
    }
}


- (void)performBatch:(ASListNodeBatch *)batch async:(BOOL)async completion:(void (^)())completion
{
    ASListNodeBatchInternal *b = [[ASListNodeBatchInternal alloc] initWithBatch:batch];
    
    // Right now we only support the main thread...
    
    for(ASListNodeOperation *operation in b.operations) {
        
        switch(operation.type) {
            case ASListNodeOperationTypeInsert:
                [self executeInsertOperation:operation];
                break;
                
            case ASListNodeOperationTypeDelete:
                break;
                
            case ASListNodeOperationTypeMove:
                break;
                
            case ASListNodeOperationTypeReplace:
                break;
        }
    }
    
    
}


-(void)performBatch:(ASListNodeBatch *)batch
{
    [self performBatch:batch async:NO completion:nil];
}


- (void)performBatchBlock:(void (^)(ASListNodeBatch *))batchBlock
{
    ASListNodeBatch *batch = [[ASListNodeBatch alloc] init];
    
    batchBlock(batch);
    
    [self performBatch:batch async:NO completion:nil];
}


#pragma mark - ASDisplayNode


#pragma mark - ASListNodeScrollViewDelegate

- (void)listNodeScrollViewLayoutSubviews:(ASListNodeScrollView *)scrollView
{
    [self layoutVisibleCells];
}

#pragma mark - UIScrollViewDelegate



@end
