//
//  PlaceAroundTableView.m
//  CMDataCollectTool
//
//  Created by PC on 15/8/7.
//  Copyright (c) 2015年 autonavi. All rights reserved.
//

#import "PlaceAroundTableView.h"

#define kMoreButtonTitle @"更多..."

@interface PlaceAroundTableView()

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *searchPoiArray;

@property (nonatomic, strong) AMapPOI *selectedPoi;

@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@property (nonatomic, assign) BOOL isFromMoreButton;
@property (nonatomic, strong) UIButton *moreButton;

@end

@implementation PlaceAroundTableView

#pragma mark - Interface

- (AMapPOI *)selectedTableViewCellPoi
{
    return self.selectedPoi;
}

#pragma mark - AMapSearchDelegate

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (self.isFromMoreButton == YES)
    {
        self.isFromMoreButton = NO;
    }
    else
    {
        [self.searchPoiArray removeAllObjects];
        [self.moreButton setTitle:kMoreButtonTitle forState:UIControlStateNormal];
        self.moreButton.enabled = YES;
        self.moreButton.backgroundColor = [UIColor whiteColor];
    }

    if (response.pois.count == 0)
    {
        [self.moreButton setTitle:@"没有数据了.." forState:UIControlStateNormal];
        self.moreButton.enabled = NO;
        self.moreButton.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.4];
        
        self.selectedIndexPath = nil;
        [self.tableView reloadData];
        return;
    }
    
    [response.pois enumerateObjectsUsingBlock:^(AMapPOI *obj, NSUInteger idx, BOOL *stop) {
        [self.searchPoiArray addObject:obj];
    }];
    
    self.selectedIndexPath = nil;
    [self.tableView reloadData];
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    if (response.regeocode != nil)
    {
        self.currentAddress = response.regeocode.formattedAddress;
        
        NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType= UITableViewCellAccessoryCheckmark;
    self.selectedIndexPath = indexPath;
    
    if (indexPath.section == 0)
    {
        self.selectedPoi = nil;
        [self.delegate didPositionCellTapped];
        return ;
    }
    
    self.selectedPoi = self.searchPoiArray[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(didTableViewSelectedChanged:)])
    {
        [self.delegate didTableViewSelectedChanged:self.selectedPoi];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
}

#pragma mark - UITableView Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reusedIndentifier = @"reusedIndentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reusedIndentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reusedIndentifier];
    }
    if (indexPath.section == 0)
    {
        cell.textLabel.text = @"[位置]";
        cell.detailTextLabel.text = self.currentAddress;
    }
    else
    {
        AMapPOI *poi = self.searchPoiArray[indexPath.row];
        cell.textLabel.text = poi.name;
        cell.detailTextLabel.text = poi.address;
    }
    
    if (self.selectedIndexPath && self.selectedIndexPath.section == indexPath.section && self.selectedIndexPath.row == indexPath.row)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 1;
    }
    else
    {
        return self.searchPoiArray.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

#pragma mark - Handle Action

- (void)actionMoreButtonTapped
{
    // 防止快速连续点两次
    if (self.isFromMoreButton == YES)
    {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didLoadMorePOIButtonTapped)])
    {
        self.isFromMoreButton = YES;
        [self.delegate didLoadMorePOIButtonTapped];
    }
}

#pragma mark - Initialization

- (NSMutableArray *)searchPoiArray
{
    if (_searchPoiArray == nil)
    {
        _searchPoiArray = [[NSMutableArray alloc] init];
    }
    return _searchPoiArray;
}

- (void)initTableViewFooter
{
#define kMoreButtonMargin   20
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), 60)];
    
    UIButton *moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    moreBtn.frame = footer.bounds;
    [moreBtn setTitle:kMoreButtonTitle forState:UIControlStateNormal];
    [moreBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [moreBtn setTitleColor:[[UIColor grayColor] colorWithAlphaComponent:0.4] forState:UIControlStateHighlighted];
    moreBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    moreBtn.titleEdgeInsets = UIEdgeInsetsMake(0, kMoreButtonMargin, 0, 0);
    [moreBtn addTarget:self action:@selector(actionMoreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.moreButton = moreBtn;
    
    [footer addSubview:moreBtn];
    
    UIView *upLineView = [[UIView alloc] initWithFrame:CGRectMake(kMoreButtonMargin, 3, CGRectGetWidth(self.bounds) - kMoreButtonMargin, 0.5)];
    upLineView.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.4];
    [footer addSubview:upLineView];
    
    self.tableView.tableFooterView = footer;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.tableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.isFromMoreButton = NO;
        
        [self addSubview:self.tableView];
        
        [self initTableViewFooter];
    }
    
    return self;
}


@end
