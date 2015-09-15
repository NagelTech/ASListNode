//
//  ASListNodeScrollView.h
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ASListNodeScrollViewDelegate;


@interface ASListNodeScrollView : UIScrollView

@property(nonatomic,weak) id<UIScrollViewDelegate,ASListNodeScrollViewDelegate> delegate;

@end


@protocol ASListNodeScrollViewDelegate <NSObject>

@required

- (void)listNodeScrollViewLayoutSubviews:(ASListNodeScrollView *)scrollView;

@end
