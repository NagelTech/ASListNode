//
//  ViewController.m
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import "ViewController.h"

#import "ASListNode.h"


@interface ViewController () <ASListNodeDataSource, ASListNodeDelegate>

@end

@implementation ViewController {
    ASListNode *_listNode;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_listNode) {
        _listNode = [[ASListNode alloc] init];
        _listNode.backgroundColor = [UIColor lightGrayColor];
        _listNode.frame = (CGRect) { .size=self.view.bounds.size };
        _listNode.dataSource = self;
        _listNode.delegate = self;

        [self.view addSubview:_listNode.view];

        [_listNode reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASListNodeDataSource


- (NSUInteger)listNode:(ASListNode *)listNode numberOfItemsInSection:(NSUInteger)section {
    return 100;
}

- (ASCellNode *)listNode:(ASListNode *)listNode cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ASTextCellNode *cellNode = [[ASTextCellNode alloc] init];

    cellNode.text = [NSString stringWithFormat:@"Row #%zd", indexPath.row];

    return cellNode;
}


#pragma mark - ASlistNodeDelegate



@end
