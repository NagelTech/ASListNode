//
//  ViewController.m
//  ASListNode
//
//  Created by Ethan Nagel on 9/11/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import "ViewController.h"

#import "ASListNode.h"


static const int NUM_ROWS = 200;


@interface ViewController () <ASListNodeDataSource, ASListNodeDelegate>

@end

@implementation ViewController {
    ASListNode *_listNode;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"ASListNode Test";

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Top" style:UIBarButtonItemStylePlain target:self action:@selector(scrollToTop:)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Bottom" style:UIBarButtonItemStylePlain target:self action:@selector(scrollToBottom:)];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (!_listNode) {
        _listNode = [[ASListNode alloc] init];
        _listNode.backgroundColor = [UIColor whiteColor];
        CGRect frame = CGRectMake(0, 44, self.view.bounds.size.width, self.view.bounds.size.height-44);
        _listNode.frame = frame;
        _listNode.dataSource = self;
        _listNode.delegate = self;

        [self.view addSubview:_listNode.view];

        // start out in the middle...
        
        [_listNode scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:NUM_ROWS/2 inSection:0] atScrollPosition:ASListNodePositionMiddle animated:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBActions


- (IBAction)scrollToTop:(id)sender {
    [_listNode scrollToTopAnimated:YES];
}


- (IBAction)scrollToBottom:(id)sender {
    [_listNode scrollToEndAnimated:YES];
}

#pragma mark - ASListNodeDataSource


- (NSUInteger)listNode:(ASListNode *)listNode numberOfItemsInSection:(NSUInteger)section {
    return NUM_ROWS;
}

- (ASCellNode *)listNode:(ASListNode *)listNode cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ASTextCellNode *cellNode = [[ASTextCellNode alloc] init];

    cellNode.text = [NSString stringWithFormat:@"Row #%zd", indexPath.row];

    return cellNode;
}


#pragma mark - ASlistNodeDelegate



@end
