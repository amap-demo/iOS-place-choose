本工程为基于高德地图iOS SDK进行封装，实现了通过地图中心进行兴趣点选择的例子
## 前述 ##
- [高德官网申请Key](http://lbs.amap.com/dev/#/).
- 阅读[开发指南](http://lbs.amap.com/api/ios-sdk/summary/).
- 工程基于iOS 3D地图SDK和搜索SDK实现

## 功能描述 ##
基于3D地图SDK和搜索SDK进行封装，通过屏幕中心点经纬度进行逆地理编码搜索和POI搜索。

## 核心类/接口 ##
| 类    | 接口  | 说明   | 版本  |
| -----|:-----:|:-----:|:-----:|
| AMapSearchAPI	| - (void)AMapReGoecodeSearch:(AMapReGeocodeSearchRequest *)request; | 逆地址编码查询接口 | v4.0.0 |
| AMapSearchAPI	| - (void)AMapPOIAroundSearch:(AMapPOIAroundSearchRequest *)request; | POI 周边查询接口 | v4.0.0 |
| PlaceAroundTableView	| --- | 继承自UIView，实现了显示逆地理以及POI周边搜索结果，并相应事件。 | --- |


## 核心难点 ##

```
/* 定位回调中进行逆地理和周边poi查询. */
- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    if(!updatingLocation)
        return ;
    
    if (userLocation.location.horizontalAccuracy < 0)
    {
        return ;
    }

    // only the first locate used.
    if (!self.isLocated)
    {
        self.isLocated = YES;
        
        [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude)];
        
        [self actionSearchAround];
        
        self.mapView.userTrackingMode = MAUserTrackingModeFollow;
    }
}

```

```
/* 地图移动回调 */
- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    if (!self.isMapViewRegionChangedFromTableView && self.mapView.userTrackingMode == MAUserTrackingModeNone)
    {
        [self actionSearchAround];
    }
    self.isMapViewRegionChangedFromTableView = NO;
}

```

```
/* PlaceAroundTableView中实现搜索结果回调delegate */
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response
{
    if (self.isFromMoreButton == YES)
    {
        self.isFromMoreButton = NO;
    }
    else
    {
        [self.searchPoiArray removeAllObjects];
        [self.moreButton setTitle:@"更多.." forState:UIControlStateNormal];
        self.moreButton.enabled = YES;
        self.moreButton.backgroundColor = [UIColor whiteColor];
    }

    if (response.pois.count == 0)
    {
        NSLog(@"没有数据了");
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
        self.currentRedWaterPosition = response.regeocode.formattedAddress;
        
        NSIndexPath *reloadIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView reloadRowsAtIndexPaths:@[reloadIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}
```