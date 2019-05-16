//
//  ViewController.swift
//  AMapPlaceChooseDemo-swift
//
//  Created by hanxiaoming on 17/1/9.
//  Copyright © 2017年 FENGSHENG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MAMapViewDelegate, PlaceAroundTableViewDeleagate {
    
    var search: AMapSearchAPI!
    var mapView: MAMapView!
    
    var tableView: PlaceAroundTableView!
    var centerAnnotationView: UIImageView!
    var locationBtn: UIButton!
    var imageLocated: UIImage!
    var imageNotLocate: UIImage!

    var searchTypeSegment: UISegmentedControl!
    var searchTypes: Array<String>!
    var currentType: String?
    
    var isMapViewRegionChangedFromTableView: Bool = false
    var isLocated: Bool = false
    var searchPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.gray
        
        AMapServices.shared().apiKey = "ecf3d01306bb8e88cb84e3d435428f7c"

        initTableView()
        initSearch()
        initMapView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initCenterView()
        initLocationButton()
        initSearchTypeView()
        
        self.mapView.zoomLevel = 17
        self.mapView.showsUserLocation = true

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    func initTableView() {
        
        self.tableView = PlaceAroundTableView(frame: CGRect(x: 0, y: self.view.bounds.height / 2.0, width: self.view.bounds.width, height: self.view.bounds.height / 2.0))
        self.tableView.delegate = self;
        
        self.view.addSubview(self.tableView)
    }
    
    func initSearch() {
        search = AMapSearchAPI()
        search.delegate = self.tableView
    }
    
    func initMapView() {
        mapView = MAMapView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height / 2.0))
        mapView.delegate = self
        self.view.addSubview(mapView)
    }

    
    func initCenterView() {
        self.centerAnnotationView = UIImageView(image: UIImage(named: "wateRedBlank"))
        
        self.centerAnnotationView.center = CGPoint(x: self.mapView.center.x, y: self.mapView.center.y - self.centerAnnotationView.bounds.height / 2.0)
        
        self.mapView.addSubview(self.centerAnnotationView)
    }
    
    func initLocationButton() {
        
        self.imageLocated = UIImage(named: "gpssearchbutton")!
        self.imageNotLocate = UIImage(named: "gpsnormal")!
        self.locationBtn = UIButton(frame: CGRect(x: CGFloat(self.mapView.bounds.width - 40), y: CGFloat(self.mapView.bounds.height - 50), width: CGFloat(32), height: CGFloat(32)))
        self.locationBtn.autoresizingMask = .flexibleTopMargin
        self.locationBtn.backgroundColor = UIColor.white
        self.locationBtn.layer.cornerRadius = 3
        self.locationBtn.addTarget(self, action: #selector(self.actionLocation), for: .touchUpInside)
        self.locationBtn.setImage(self.imageNotLocate, for: .normal)
        self.view.addSubview(self.locationBtn)
    }
    
    func initSearchTypeView() {
        
        self.searchTypes = ["住宅", "学校", "楼宇", "商场"]
        self.currentType = self.searchTypes.first!
        self.searchTypeSegment = UISegmentedControl(items: self.searchTypes)
        self.searchTypeSegment.frame = CGRect(x: CGFloat(10), y: CGFloat(self.mapView.bounds.height - 50), width: CGFloat(self.mapView.bounds.width - 80), height: CGFloat(32))
        self.searchTypeSegment.layer.cornerRadius = 3
        self.searchTypeSegment.backgroundColor = UIColor.white
        self.searchTypeSegment.autoresizingMask = .flexibleTopMargin
        self.searchTypeSegment.selectedSegmentIndex = 0
        self.searchTypeSegment.addTarget(self, action: #selector(self.actionTypeChanged), for: .valueChanged)
        self.view.addSubview(self.searchTypeSegment)
    }
    
    
    //MARK: - Action
    
    func actionSearchAround(at coordinate: CLLocationCoordinate2D) {
        self.searchReGeocode(withCoordinate: coordinate)
        self.searchPoi(withCoordinate: coordinate)
        self.searchPage = 1
        self.centerAnnotationAnimimate()
    }
    
    @objc func actionLocation() {
        if self.mapView.userTrackingMode == .follow {
            self.mapView.setUserTrackingMode(.none, animated: true)
        }
        else {
            self.searchPage = 1
            self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(0.5 * Double(NSEC_PER_SEC)) / Double(NSEC_PER_SEC), execute: {() -> Void in
                // 因为下面这句的动画有bug，所以要延迟0.5s执行，动画由上一句产生
                self.mapView.setUserTrackingMode(.follow, animated: true)
            })
        }
    }
    
    @objc func actionTypeChanged(_ sender: UISegmentedControl) {
        self.currentType = self.searchTypes[sender.selectedSegmentIndex]
        self.actionSearchAround(at: self.mapView.centerCoordinate)
    }
    
    
    func centerAnnotationAnimimate() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {() -> Void in
            var center = self.centerAnnotationView.center
            center.y -= 20
            self.centerAnnotationView.center = center
        }, completion: { _ in })
        UIView.animate(withDuration: 0.45, delay: 0, options: .curveEaseIn, animations: {() -> Void in
            var center = self.centerAnnotationView.center
            center.y += 20
            self.centerAnnotationView.center = center
        }, completion: { _ in })
    }
    
    func searchPoi(withCoordinate coord: CLLocationCoordinate2D) {
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(coord.latitude), longitude: CGFloat(coord.longitude))
        request.radius = 1000
        request.types = self.currentType
        request.sortrule = 0
        request.page = self.searchPage
        self.search.aMapPOIAroundSearch(request)
    }
    
    func searchReGeocode(withCoordinate coord: CLLocationCoordinate2D) {
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(coord.latitude), longitude: CGFloat(coord.longitude))
        request.requireExtension = true
        self.search.aMapReGoecodeSearch(request)
    }
    
    //MARK:- PlaceAroundTableViewDeleagate
    
    func didTableViewSelectedChanged(selectedPOI: AMapPOI!) {
        if self.isMapViewRegionChangedFromTableView == true {
            return
        }
        self.isMapViewRegionChangedFromTableView = true
        let location = CLLocationCoordinate2D(latitude: CLLocationDegrees(selectedPOI.location.latitude), longitude: CLLocationDegrees(selectedPOI.location.longitude))
        self.mapView.setCenter(location, animated: true)
    }
    
    func didLoadMorePOIButtonTapped() {
        self.searchPage += 1
        self.searchPoi(withCoordinate: self.mapView.centerCoordinate)
    }
    
    func didPositionCellTapped() {
        if self.isMapViewRegionChangedFromTableView == true {
            return
        }
        self.isMapViewRegionChangedFromTableView = true
        self.mapView.setCenter(self.mapView.userLocation.coordinate, animated: true)
    }
    
    //MARK: - MAMapViewDelegate
    
    func mapViewRequireLocationAuth(_ locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    func mapView(_ mapView: MAMapView!, didChange mode: MAUserTrackingMode, animated: Bool) {
        if mode == .none {
            self.locationBtn.setImage(self.imageNotLocate, for: .normal)
        }
        else {
            self.locationBtn.setImage(self.imageLocated, for: .normal)
        }
    }
    
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        if !updatingLocation {
            return
        }
        if userLocation.location.horizontalAccuracy < 0 {
            return
        }
        // only the first locate used.
        if !self.isLocated {
            self.isLocated = true
            self.mapView.userTrackingMode = .follow
            self.mapView.centerCoordinate = userLocation.location.coordinate
            self.actionSearchAround(at: userLocation.location.coordinate)
        }
    }
    
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
        if !self.isMapViewRegionChangedFromTableView && self.mapView.userTrackingMode == .none {
            self.actionSearchAround(at: self.mapView.centerCoordinate)
        }
        self.isMapViewRegionChangedFromTableView = false
    }
}

