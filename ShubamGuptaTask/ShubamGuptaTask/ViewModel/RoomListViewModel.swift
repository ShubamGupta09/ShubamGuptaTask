//
//  RoomListViewModel.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 26/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import Foundation
import UIKit
import Reachability

//MARK: Protocol and Delegates
protocol RoomListViewModelDelegates: NSObjectProtocol {
    func tableViewReload()
    func moveOneVcToOther(roomId: Int)
}

class RoomListViewModel: NSObject {
    var parentVC = UITableViewController()
    let refreshControl = UIRefreshControl()
    let reachability = try! Reachability()
    weak var delegates: RoomListViewModelDelegates?
    
    var roomList: [RoomListData] = [] {
        didSet {
            delegates?.tableViewReload()
        }
    }
    
    //MARK: Initalizer
    init(parent: UITableViewController,withDelegates delegate: RoomListViewModelDelegates?) {
        parentVC = parent
        delegates = delegate
    }

    //MARK: RefreshTableView
    func refreshTableView(tableView: UITableView) {
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshWeatherData(_:)), for: .valueChanged)
    }
    
    //MARK: Reachability
    func checkReachability() {
        reachability.whenReachable = { _ in
            self.roomListApiCallBack()
            print("YES INTERNET IS AVAILABLE")
        }
        
        reachability.whenUnreachable = { _ in
            print("NO Internet Connection")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(internetChanged), name: Notification.Name.reachabilityChanged, object: reachability)
        do{
          try reachability.startNotifier()
        }catch{
          print("could not start reachability notifier")
        }
    }
    
    @objc func internetChanged(note: Notification) {
        let reachab = note.object as! Reachability
        if reachab.connection == .unavailable {
            print("NO Inernet Connection")
        } else {
            print("Internet Availble")
        }
    }
    
    @objc private func refreshWeatherData(_ sender: Any) {
        //API Call Back
        roomListApiCallBack()
    }
    
    //MARK: CellForRow
    func cellForRowAt(_ cell: UITableViewCell, indexPath: IndexPath) {
        cell.textLabel?.text = "\(roomList[indexPath.row].org.name)-\(roomList[indexPath.row].property.name) - \(roomList[indexPath.row].room.name)"
    }
    
    //MARK: NumberOfRows
    func numberOfRowsInSection() -> Int {
        return roomList.count
    }
    
    //MARK: didSelect
    func didSelectRowAt(indexPath: IndexPath) {
        let roomIdValue = roomList[indexPath.row].room.id
        print(roomIdValue)
        delegates?.moveOneVcToOther(roomId: roomIdValue)
    }
    
    //MARK: RoomListAPI CallBack
    func roomListApiCallBack() {
        let timeStamp: Int = calculateTimeStamp()
        let timestampValue: [URLQueryItem] = [URLQueryItem(name: "timestamp", value: "\(timeStamp)")]
        Middleware.init { (status, roomListData, message) in
            switch status {
            case .success:
                guard let info = roomListData as? RoomList else {
                    self.parentVC.showToast(message: "Something went wrong", font: .systemFont(ofSize: 12.0))
                    return
                }
                self.refreshControl.endRefreshing()
                print(info.data[0])
                self.roomList = info.data
                
            case .badRequest:
                break
            default:
                break
            }
        }.roomList(timeStamp: timestampValue)
    }
    
    //MARK: Calculating TimeStamp
    func calculateTimeStamp() -> Int {
        let decimalTimestamp = NSDate().timeIntervalSince1970
        print(Int(decimalTimestamp))
        return Int(decimalTimestamp)
    }
}
