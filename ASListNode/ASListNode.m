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


@interface ASListNode () <UIScrollViewDelegate>

@property (nonatomic,readonly) ASListNodeScrollView *view;

@end


@implementation ASListNode {

    NSMutableDictionary *_cells;    // NSIndexPath -> ASCellNode
    NSIndexPath *_topIndexPath;
    CGFloat _topCellOffset;
    NSMutableArray *_visibleCells;
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
        _topCellOffset = 0;
        _visibleCells = [[NSMutableArray alloc] init];
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


- (void)setLayerBacked:(BOOL)layerBacked
{
    ASDisplayNodeAssert(!layerBacked, @"ASListNode does not support layer-backing.");
}


- (NSIndexPath *)prevIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section;
    NSUInteger row;

    NSUInteger numberOfSections = [self numberOfSections];

    if (!indexPath) {
        section = numberOfSections - 1;
        if (section == -1) {
            return nil;
        }
        row = [self numberOfItemsInSection:section] - 1;
    }

    // todo

    return nil;
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


- (NSUInteger)numberOfSections
{
    return [self.dataSource numberOfSectionsInListNode:self];
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

- (void)layoutVisibleNodes
{
    CGRect visibleArea = (CGRect) { .origin=self.view.contentOffset, .size=self.bounds.size };

    // remove now hidden leading items from the list...

    while(_visibleCells.count > 0) {
        ASCellNode *cell = _visibleCells.firstObject;

        if (CGRectIntersectsRect(cell.frame, visibleArea)) {
            break;
        }

        [_visibleCells removeObjectAtIndex:0];

        _topIndexPath = [self nextIndexPath:_topIndexPath];
        _topCellOffset += cell.bounds.size.height;
    }

    // stack items on the top if we have any...

    ASCellNode *topCell = _visibleCells.firstObject;

    while(topCell && topCell.frame.origin.y < visibleArea.origin.y) {
        ASCellNode *newCell =
    }




}

- (void)reloadData
{
    NSUInteger numberOfItems = [self.dataSource listNode:self numberOfItemsInSection:0];

    CGSize constrainedSize = (CGSize) {self.bounds.size.width, CGFLOAT_MAX};

    CGFloat position = 0;

    for(NSUInteger row=0; row<numberOfItems; row++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];

        ASCellNode *cell = [self cellForItemAtIndexPath:indexPath];

        CGSize cellSize = [cell measure:constrainedSize];

        cell.frame = (CGRect) { .origin={0,position}, .size=cellSize };

        [self.view addSubview:cell.view];

        position += cellSize.height;
    }

    self.view.contentSize = (CGSize){self.bounds.size.width, position};
}


#pragma mark - UIScrollViewDelegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSLog(@"scrollViewDidScroll contentOffset = %f,%f", scrollView.contentOffset.x, scrollView.contentOffset.y);
}


@end
