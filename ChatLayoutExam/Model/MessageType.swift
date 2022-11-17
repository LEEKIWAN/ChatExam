//
//  MessageTypeTableViewCell.swift
//  Waiker
//
//  Created by kiwan on 2022/07/26.
//

import UIKit

enum MessageType: String, Codable {
    case text = "TEXT"
    case image = "IMAGE"
    case link = "LINK"
    case video = "VIDEO"
    case userJoin = "USER_JOIN"
    case userExit = "USER_EXIT"
    case userBan = "USER_BAN"
    case userUnban = "USER_UNBAN"
    case noticeFix = "NOTICE_FIX"
    case roleChangedToMaster = "ROLE_CHANGED_TO_MASTER"
    case roleChangedToSub_master = "ROLE_CHANGED_TO_SUB_MASTER"
    case roleChangedToGeneral = "ROLE_CHANGED_TO_GENERAL"
    case readToHere = "READ_TO_HERE"
    case welcome = "WELCOME"
//    case deletedByAdmin = "DELETED_BY_ADMIN"
}
