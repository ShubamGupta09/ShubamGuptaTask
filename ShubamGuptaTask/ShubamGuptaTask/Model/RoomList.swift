//
//  RoomList.swift
//  ShubamGuptaTask
//
//  Created by Shubam Gupta on 25/07/20.
//  Copyright © 2020 Shubam. All rights reserved.
//

import Foundation

// MARK: - RoomList
struct RoomList: Codable {
    let data: [RoomListData]
    let success: Bool
}

// MARK: - RoomListData
struct RoomListData: Codable {
    let org, property, room: Org
}

// MARK: - Org
struct Org: Codable {
    let id: Int
    let name: String
}

