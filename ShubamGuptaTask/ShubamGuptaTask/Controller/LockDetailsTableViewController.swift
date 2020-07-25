//
//  LockDetailsTableViewController.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 25/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import UIKit

class LockDetailsTableViewController: UITableViewController {

    //MARK: ViewModel
    lazy var LockDetailsVM = LockDetailViewModel(parent: self, withDelegates: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LockDetailsVM.lockDetailsApiCallBack()
        LockDetailsVM.tableViewSetUp(tableView)
    }
    
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LockDetailsTableViewCell", for: indexPath) as! LockDetailsTableViewCell
        LockDetailsVM.cellForRowAt(cell,indexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

//MARK: Delegates Method
extension LockDetailsTableViewController: LockDetailViewModelDelegates {
    func tableViewReload() {
        tableView.reloadData()
    }
}

extension UITableViewController {

func showToast(message : String, font: UIFont) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-120, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
