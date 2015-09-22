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

typedef NS_ENUM(NSInteger, ASListNodeOperationType) {
    ASListNodeOperationTypeInsert,
    ASListNodeOperationTypeDelete,
    ASListNodeOperationTypeMove,
    ASListNodeOperationTypeReplace,
};

@interface ASListNodeOperation : NSObject<NSCopying>

@property (nonatomic,readonly) ASListNodeOperationType type;
@property (nonatomic,readonly) ASListNodeIndex sourceIndex;
@property (nonatomic,readonly) ASListNodeIndex destIndex;
@property (nonatomic,readonly,nullable) NSArray *items;
@property (nonatomic,readonly) NSInteger count;

+ (nonnull instancetype)insertAtIndex:(ASListNodeIndex)destIndex items:(nonnull NSArray *)items;
+ (nonnull instancetype)deleteFromIndex:(ASListNodeIndex)sourceIndex count:(NSInteger)count;
//+ (instancetype)moveFromIndex:(ASListNodeIndex)sourceIndex toIndex:(ASListNodeIndex)destIndex count:(NSInteger)count;
//+ (instancetype)replaceAtIndex:(ASListNodeIndex)destIndex items:(NSArray *)items;

@end

@interface ASListNodeBatch : NSObject

@property (nonatomic,readonly,nonnull,copy) NSArray<ASListNodeOperation *> *operations;

- (nonnull instancetype)init;

- (void)addOperation:(nonnull ASListNodeOperation *)operation;

- (void)insertAtIndex:(ASListNodeIndex)destIndex items:(nonnull NSArray *)items;
- (void)deleteFromIndex:(ASListNodeIndex)sourceIndex count:(NSInteger)count;

@end


@interface ASListNode : ASDisplayNode

@property (nonatomic, weak) id<ASListNodeDataSource> dataSource;
@property (nonatomic, weak) id<ASListNodeDelegate> delegate;
@property (nonatomic,copy,nonnull) NSArray *items;
@property (nonatomic) UIEdgeInsets contentInset;

- (nonnull instancetype)init;

- (nonnull ASCellNode *)cellForItemAtIndex:(ASListNodeIndex)index;

- (void)scrollToItemAtIndex:(ASListNodeIndex)index atScrollPosition:(ASListNodeScrollPosition)scrollPosition animated:(BOOL)animated;

- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToEndAnimated:(BOOL)animated;

/// Execute batch synchronously
- (void)performBatch:(nonnull ASListNodeBatch *)batch;
- (void)performBatchBlock:(nonnull void (^)(ASListNodeBatch * _Nonnull batch))batchBlock;

/// perform batch asynchronously
//- (void)beginBatch:(ASListNodeBatch *)batch completion:(void (^)())completionHandler;
//- (void)beginBatchBlock:(void (^)(ASListNodeBatch *batch))batchBlock completion:(void (^)())completionHandler;

@end


@protocol ASListNodeDataSource <NSObject>

@required

- (nonnull ASCellNode *)listNode:(nonnull ASListNode *)listNode cellForItem:(nonnull id)item atIndex:(ASListNodeIndex)index;

@end


@protocol ASListNodeDelegate <NSObject>

@required

@optional

@end