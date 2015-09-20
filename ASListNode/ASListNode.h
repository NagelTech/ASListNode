//
//  ASListNode.h
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import "ASDisplayNode.h"
#import <ASCellNode.h>

typedef NS_ENUM(NSInteger, ASListNodeScrollPosition) {
    ASListNodePositionTop,
    ASListNodePositionMiddle,
    ASListNodePositionBottom,
};


typedef NSInteger ASListNodeIndex;

extern const ASListNodeIndex ASListNodeIndexInvalid;


@protocol ASListNodeDataSource;
@protocol ASListNodeDelegate;


@interface ASListNode : ASDisplayNode

@property (nonatomic, weak) id<ASListNodeDataSource> dataSource;
@property (nonatomic, weak) id<ASListNodeDelegate> delegate;

@property (nonatomic,copy) NSArray *items;

- (instancetype)init;

- (ASCellNode *)cellForItemAtIndex:(ASListNodeIndex)index;

- (void)scrollToItemAtIndex:(ASListNodeIndex)index atScrollPosition:(ASListNodeScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToEndAnimated:(BOOL)animated;

@end


@protocol ASListNodeDataSource <NSObject>

@required

- (ASCellNode *)listNode:(ASListNode *)listNode cellForItem:(id)item atIndex:(ASListNodeIndex)index;

@end


@protocol ASListNodeDelegate <NSObject>

@required

@optional

@end