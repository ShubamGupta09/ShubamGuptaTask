//
//  RoomListTableViewController.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 25/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import UIKit
import Reachability

class RoomListTableViewController: UITableViewController {

    //MARK: ViewModel
    lazy var RoomListVM = RoomListViewModel(parent: self, withDelegates: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RoomListVM.checkReachability()
        RoomListVM.refreshTableView(tableView: tableView)
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return RoomListVM.numberOfRowsInSection()
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        RoomListVM.cellForRowAt(cell, indexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        RoomListVM.didSelectRowAt(indexPath: indexPath)
    }
}

//MARK: Delegate Method
extension RoomListTableViewController: RoomListViewModelDelegates {
    func moveOneVcToOther(roomId: Int) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "LockDetailsTableViewController") as! LockDetailsTableViewController
        nextViewController.LockDetailsVM.roomId = roomId
        navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    func tableViewReload() {
        tableView.reloadData()
    }
    
    
}
