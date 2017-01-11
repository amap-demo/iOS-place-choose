//
//  PlaceAroundTableView.h
//  CMDataCollectTool
//
//  Created by PC on 15/8/7.
//  Copyright (c) 2015年 autonavi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapView.h>
#import <AMapSearchKit/AMapSearchKit.h>

@protocol PlaceAroundTableViewDeleagate <NSObject>

- (void)didTableViewSelectedChanged:(AMapPOI *)selectedPoi;

- (void)didLoadMorePOIButtonTapped;

- (void)didPositionCellTapped;

@end




@interface PlaceAroundTableView : UIView <UITableViewDataSource, UITableViewDelegate, AMapSearchDelegate>

@property (nonatomic, weak) id<PlaceAroundTableViewDeleagate> delegate;

@property (nonatomic, copy) NSString *currentAddress;

- (instancetype)initWithFrame:(CGRect)frame;

- (AMapPOI *)selectedTableViewCellPoi;

@end

