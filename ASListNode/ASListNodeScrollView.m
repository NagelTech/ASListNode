//
//  ASListNodeScrollView.m
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import "ASListNodeScrollView.h"

@implementation ASListNodeScrollView

@dynamic delegate;

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.delegate listNodeScrollViewLayoutSubviews:self];
}


@end
