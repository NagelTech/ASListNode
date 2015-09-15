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

@protocol ASListNodeDataSource;
@protocol ASListNodeDelegate;


@interface ASListNode : ASDisplayNode

@property (nonatomic, weak) id<ASListNodeDataSource> dataSource;
@property (nonatomic, weak) id<ASListNodeDelegate> delegate;

- (instancetype)init;

- (NSUInteger)numberOfSections;
- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;
- (ASCellNode *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(ASListNodeScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToEndAnimated:(BOOL)animated;

@end


@protocol ASListNodeDataSource <NSObject>

@required

- (NSUInteger)listNode:(ASListNode *)listNode numberOfItemsInSection:(NSUInteger)section;

- (ASCellNode *)listNode:(ASListNode *)listNode cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSUInteger)numberOfSectionsInListNode:(ASListNode *)listNode;

@end


@protocol ASListNodeDelegate <NSObject>

@required

@optional

@end