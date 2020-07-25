//
//  LockDetailViewModel.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 26/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import Foundation
import UIKit

//MARK: Protocol and Delegatess
protocol LockDetailViewModelDelegates: NSObjectProtocol {
    func tableViewReload()
}

class LockDetailViewModel: NSObject {
    
    var roomId: Int!
    var parentVC = UITableViewController()
    weak var delegates: LockDetailViewModelDelegates?
    var lockDetailsData: LockDetails? {
        didSet {
            delegates?.tableViewReload()
        }
    }
    
    //MARK: Initalizer
    init(parent: UITableViewController,withDelegates delegate: LockDetailViewModelDelegates?) {
        parentVC = parent
        delegates = delegate
    }
    
    //MARK: TableViewSetUP
    func tableViewSetUp(_ tableView: UITableView) {
        tableView.register(UINib(nibName: "LockDetailsTableViewCell", bundle: nil), forCellReuseIdentifier: "LockDetailsTableViewCell")
    }
    
    //MARK: LockDetailsAPICallBack
    func lockDetailsApiCallBack() {
        let timeStamp: Int = calculateTimeStamp()
        let timestampValue: [URLQueryItem] = [URLQueryItem(name: "timestamp", value: "\(timeStamp)"),URLQueryItem(name: "roomId", value: "\(roomId!)")]
        Middleware.init { (status, lockDetailsListData, message) in
            switch status {
            case .success:
                guard let info = lockDetailsListData as? LockDetails else {
                    self.parentVC.showToast(message: "Something went wrong", font: .systemFont(ofSize: 12.0))
                    return
                }
                self.lockDetailsData = info
                
            case .badRequest:
                break
            default:
                break
                //self.showToast(with: message)
            }
        }.lockDetailsList(timeStamp: timestampValue)
    }

    //MARK: CalculateTimeStamp
    func calculateTimeStamp() -> Int {
        let decimalTimestamp = NSDate().timeIntervalSince1970
        print(Int(decimalTimestamp))
        return Int(decimalTimestamp)
    }
    
    //MARK: CellForRow
    func cellForRowAt(_ cell: LockDetailsTableViewCell,indexPath: IndexPath) {
        if let lockData = lockDetailsData {
            cell.lblName.text = "Name: \(lockData.name)"
            cell.lblMac.text = "Mac Address: \(lockData.MAC)"
            cell.lblDescription.text = "Description: \(lockData.description)"
        }
    }
}
