//
//  PlaceAroundTableView.swift
//  AMapPlaceChooseDemo
//
//  Created by hanxiaoming on 17/1/10.
//  Copyright © 2017年 FENGSHENG. All rights reserved.
//

import UIKit

let kMoreButtonTitle = "更多..."

@objc protocol PlaceAroundTableViewDeleagate: NSObjectProtocol {
    
    func didTableViewSelectedChanged(selectedPOI: AMapPOI!)
    func didLoadMorePOIButtonTapped()
    func didPositionCellTapped()
}

class PlaceAroundTableView: UIView, UITableViewDataSource, UITableViewDelegate, AMapSearchDelegate {
    weak var delegate: PlaceAroundTableViewDeleagate?

    var currentAddress: String?
    
    var tableView: UITableView!
    var searchPoiArray: Array<AMapPOI> = Array()
    var selectedIndexPath: IndexPath?
    var isFromMoreButton: Bool = false
    var moreButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initTableView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initTableView() {
        tableView = UITableView(frame: self.bounds, style: UITableViewStyle.plain)
        tableView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        
        initTableViewFooter()
        
    }
    
    func initTableViewFooter() {
        let margin: CGFloat = 20.0
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 60))
        moreButton = UIButton(type: UIButtonType.custom)
        moreButton.frame = footer.bounds
        moreButton.setTitle(kMoreButtonTitle, for: UIControlState.normal)
        moreButton.setTitleColor(UIColor.black, for: UIControlState.normal)
        moreButton.setTitleColor(UIColor.gray, for: UIControlState.highlighted)
        moreButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        moreButton.titleEdgeInsets = UIEdgeInsetsMake(0, margin, 0, 0)
        moreButton.addTarget(self, action: #selector(self.actionMoreButtonTapped), for: UIControlEvents.touchUpInside)
        
        footer.addSubview(moreButton)
        
        // line
        let line = UIView(frame: CGRect(x: margin, y: 3, width: footer.bounds.width - margin, height: 0.5))
        line.backgroundColor = UIColor.gray
        
        footer.addSubview(line)
        
        self.tableView.tableFooterView = footer
    }
    
    func actionMoreButtonTapped() {
        if isFromMoreButton || self.delegate == nil {
            return
        }
        
        self.isFromMoreButton = true
        if self.delegate!.responds(to: #selector(PlaceAroundTableViewDeleagate.didLoadMorePOIButtonTapped)) {
            self.delegate!.didLoadMorePOIButtonTapped()
        }
    }
    
    //MARK:- AMapSearchDelegate
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        print("error :\(error)")
    }
    
    /* POI 搜索回调. */
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        
        if isFromMoreButton {
            isFromMoreButton = false
        }
        else {
            self.searchPoiArray.removeAll()
            self.moreButton.setTitle(kMoreButtonTitle, for: UIControlState.normal)
            self.moreButton.isEnabled = true
            self.moreButton.backgroundColor = UIColor.white
        }
        
        if response.count == 0 {
            self.moreButton.setTitle("没有数据了...", for: UIControlState.normal)
            self.moreButton.isEnabled = false
            self.moreButton.backgroundColor = UIColor.gray
            self.selectedIndexPath = nil
            
            self.tableView.reloadData()

            return
        }
        
        self.searchPoiArray.append(contentsOf: response.pois)
        self.selectedIndexPath = nil
        self.tableView.reloadData()
    }
    
    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        
        if response.regeocode != nil {
            self.currentAddress = response.regeocode.formattedAddress;
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.none)
        }
    }
    
    //MARK:- TableViewDelegate
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell: UITableViewCell? = tableView.cellForRow(at: indexPath)
        
        if cell != nil {
            cell!.accessoryType = UITableViewCellAccessoryType.none
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell: UITableViewCell? = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.checkmark

        self.selectedIndexPath = indexPath
        
        if self.delegate == nil {
            return
        }
        
        if indexPath.section == 0 {
            if self.delegate!.responds(to: #selector(PlaceAroundTableViewDeleagate.didPositionCellTapped)) {
                self.delegate!.didPositionCellTapped()
            }
        }
        else {
            if self.delegate!.responds(to: #selector(PlaceAroundTableViewDeleagate.didTableViewSelectedChanged(selectedPOI:))) {
                let seletedPOI = self.searchPoiArray[indexPath.row]
                self.delegate!.didTableViewSelectedChanged(selectedPOI: seletedPOI)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else {
            return searchPoiArray.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    //MARK:- TableViewDataSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "demoCellIdentifier"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        
        if cell == nil {
            
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: cellIdentifier)
        }
        
        if indexPath.section == 0 {
            cell!.textLabel?.text = "[位置]";
            cell!.detailTextLabel?.text = self.currentAddress

        }
        else {
            let poi: AMapPOI = self.searchPoiArray[indexPath.row]
            cell!.textLabel?.text = poi.name
            cell!.detailTextLabel?.text = poi.address
        }
        
        if self.selectedIndexPath != nil && self.selectedIndexPath?.section == indexPath.section && self.selectedIndexPath?.row == indexPath.row {
            cell!.accessoryType = .checkmark
        }
        else {
            cell!.accessoryType = .none
        }
        return cell!
    }


}
