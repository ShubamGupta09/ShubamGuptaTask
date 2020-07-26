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
import CoreData

enum CheckInternet {
    case online
    case offline
}

//MARK: Protocol and Delegates
protocol RoomListViewModelDelegates: NSObjectProtocol {
    func tableViewReload()
    func moveOneVcToOther(roomId: Int)
}

class RoomListViewModel: NSObject {
    var parentVC = UITableViewController()
    let refreshControl = UIRefreshControl()
    let reachability = try! Reachability()
    var type: CheckInternet = .online
    var storedCoreData: [String] = [] {
        didSet{
            delegates?.tableViewReload()
        }
    }
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context: NSManagedObjectContext
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
        context = appDelegate.persistentContainer.viewContext
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
            self.type = .online
        }
        
        reachability.whenUnreachable = { _ in
            self.parentVC.showToast(message: "NO INTERNET", font: .systemFont(ofSize: 12.0))
            self.type = .offline
            self.fetchDataFromCoreData()
        }
        
        do{
          try reachability.startNotifier()
        }catch{
          print("could not start reachability notifier")
        }
    }
    
    @objc private func refreshWeatherData(_ sender: Any) {
        //API Call Back
        if type == .offline {
            self.refreshControl.endRefreshing()
            self.parentVC.showToast(message: "NO INTERNET", font: .systemFont(ofSize: 12.0))
        } else {
            self.refreshControl.endRefreshing()
            self.roomListApiCallBack()
        }
        
    }
    
    //MARK: COREDATA
    func saveDataInCoreData() {
        
        //SAVE DATA
        let entity = NSEntityDescription.entity(forEntityName: "RMListData", in: context)
        let newUser = NSManagedObject(entity: entity!, insertInto: context)
        newUser.setValue(storedCoreData, forKey: "rmData")
        do {
            print("Saved Succssfully")
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    
    func fetchDataFromCoreData() {
        
        //FetchData
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "RMListData")
        request.returnsObjectsAsFaults = false
    
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
               print(data.value(forKey: "rmData") as! [String])
                
                let data = data.value(forKey: "rmData") as! [String]
                storedCoreData.append(contentsOf: data)
                
            }
            self.refreshControl.endRefreshing()
            print("Sam \(storedCoreData.count)")
        } catch {
            parentVC.showToast(message: "Failed to Save", font: .systemFont(ofSize: 12.0))
        }
    }
    
    func deleteAllData(_ entity:String) {
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: entity))
        do {
            try context.execute(DelAllReqVar)
            storedCoreData.removeAll()
        }
        catch {
            print(error)
        }
    }
    
    //MARK: CellForRow
    func cellForRowAt(_ cell: UITableViewCell, indexPath: IndexPath) {
        if type == .online {
            cell.textLabel?.text = "\(roomList[indexPath.row].org.name)-\(roomList[indexPath.row].property.name) - \(roomList[indexPath.row].room.name)"
        } else {
            cell.textLabel?.text = "\(storedCoreData[indexPath.row])"
        }
        
    }
    
    //MARK: NumberOfRows
    func numberOfRowsInSection() -> Int {
        if type == .online {
            return roomList.count
        } else {
            return storedCoreData.count
        }
        
    }
    
    //MARK: didSelect
    func didSelectRowAt(indexPath: IndexPath) {
        if type == .online {
            let roomIdValue = roomList[indexPath.row].room.id
            print(roomIdValue)
            delegates?.moveOneVcToOther(roomId: roomIdValue)
        } else {
            self.parentVC.showToast(message: "No Internet", font: .systemFont(ofSize: 12.0))
        }
    }
    
    //MARK: RoomListAPI CallBack
    func roomListApiCallBack() {
        let timeStamp: Int = calculateTimeStamp()
        let timestampValue: [URLQueryItem] = [URLQueryItem(name: "timestamp", value: "\(timeStamp)")]
        Middleware.init { (status, roomListData, message) in
            switch status {
            case .success:
                self.deleteAllData("RMListData")
                guard let info = roomListData as? RoomList else {
                    self.parentVC.showToast(message: "Something went wrong", font: .systemFont(ofSize: 12.0))
                    return
                }
                self.refreshControl.endRefreshing()
                print(info.data.count)
                for index in 0...info.data.count - 1 {
                    let valueIndex = "\(info.data[index].org.name)-\(info.data[index].property.name)-\(info.data[index].room.name)"
                    self.storedCoreData.append(valueIndex)
                }
                print(self.storedCoreData)
                self.saveDataInCoreData()
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
