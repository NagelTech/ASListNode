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
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        _listNode.frame = frame;
        _listNode.dataSource = self;
        _listNode.delegate = self;
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        for(int index=0; index<NUM_ROWS; index++) {
            [items addObject:[NSString stringWithFormat:@"Row #%d", index]];
        }
        
        _listNode.items = items;

        _listNode.contentInset = (UIEdgeInsets) {.top = 64};

        [self.view addSubview:_listNode.view];

        // start out in the middle...

        if (NUM_ROWS > 0) {
            [_listNode scrollToItemAtIndex:NUM_ROWS/2 atScrollPosition:ASListNodePositionMiddle animated:NO];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBActions

static int sNewItemIndex = 0;

- (IBAction)scrollToTop:(id)sender {
//    [_listNode scrollToTopAnimated:YES];

    NSString *item = [NSString stringWithFormat:@"NEW ITEM %zd", sNewItemIndex];

    ASListNodeIndex index = 0;

    switch(1) {
        case 0:
            index = 0;
            break;

        case 1:
            index = _listNode.items.count/2;
            break;

        case 2:
            index = _listNode.items.count;
            break;
    }

    [_listNode performBatchBlock:^(ASListNodeBatch * _Nonnull batch) {
        [batch insertAtIndex:index items:@[item]];
    }];

    ++sNewItemIndex;
}


- (IBAction)scrollToBottom:(id)sender {
    [_listNode scrollToEndAnimated:YES];
}

#pragma mark - ASListNodeDataSource


- (ASCellNode *)listNode:(ASListNode *)listNode cellForItem:(NSString *)item atIndex:(ASListNodeIndex)index {
    ASTextCellNode *cellNode = [[ASTextCellNode alloc] init];
    
    cellNode.text = item;
    
    return cellNode;
}


#pragma mark - ASlistNodeDelegate



@end
