//
//  Member.swift
//  Waiker
//
//  Created by kiwan on 2022/07/27.
//

import UIKit

// MARK: - Member

struct SpaceMemberList: Codable {
    let memberList: [SpaceMember]?
    let memberTotalCnt: Int?
}


struct SpaceMember: Codable {
    let memberProfile: Member?
    let spaceUser: SpaceUser?
}


class Member: Codable {
    var id: Int?
    var profileImage: String?
    var nickname: String?
    var memberStatus: MemberStatus?
        
    
    init(id: Int?, profileImage: String?, nickname: String?, memberStatus: MemberStatus?) {
        self.id = id
        self.profileImage = profileImage
        self.nickname = nickname
        self.memberStatus = memberStatus
    }
}

enum MemberStatus: String, Codable {
    case normal = "NORMAL"
    case deleted = "DELETED"
    case suspended = "SUSPENDED"
    case inActive = "IN_ACTIVE"
    case deleteCompleted = "DELETE_COMPLETED"
}


struct SpaceUser: Codable {
    let id: Int?
    let memberId: Int?
    let spaceId: Int?
    let createdDt: Date?
    let banned: Bool?
    let owner: Bool?
    let admin: Bool?
    let manager: Bool?
}
