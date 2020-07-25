//
//  LockDetails.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 25/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import Foundation

// MARK: - LockDetails
struct LockDetails: Codable {
    let MAC, name, description: String
    let success: Bool
}
