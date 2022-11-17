//
//  ChattingMessageList.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit
import DifferenceKit

// MARK: - Welcome
struct ChattingMessageList: Codable {
    var messageList: [RawMessage]?
    var lastSeenMsgId: Int?
    let lastSeenMsgSentDt: Date?
}

// MARK: - MessageList
struct RawMessage: Codable {
    var id: Int = -1
    var roomId: Int?
    var channelId: Int?
//    var parentMessage: ParentRawMessage?
    var member: Member?
    var spaceUser: SpaceUser?
    var messageType: MessageType?
    var linkMessage: LinkMessage?
    var textMessage: TextMessage?
    var imageMessage: ImageMessage?
    var sentDt: Date?
    var deletedByManager: Bool?
    var deletedByWriter: Bool?
    var deletedByAdmin: Bool?
    var roomMaster: Bool?
    var roomSubMaster: Bool?
    
    
    var isLoading: Bool = false
    var isTranslated: Bool = false
    var translatedMessage: String?
        
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId
        case channelId
//        case parentMessage
        case member
        case spaceUser
        case messageType
        case linkMessage
        case textMessage
        case imageMessage
        case sentDt
        case deletedByManager
        case deletedByWriter
        case deletedByAdmin
        case roomMaster
        case roomSubMaster
    }
    
}

extension RawMessage: Differentiable {
    var differenceIdentifier: Int {
        return id
    }
    
    func isContentEqual(to source: RawMessage) -> Bool {
        return id == source.id
    }
    
}


// MARK: - TextMessage
class LinkMessage: Codable {
    var ogImage: String?
    var ogUrl: String?
    var contents: String?
    var ogTitle: String?
    var ogDesc: String?
    
    
    init(contents: String?, ogUrl: String?) {
        self.contents = contents
        self.ogUrl = ogUrl
    }
    
}

class TextMessage: Codable {
    var contents: String?
    
    init(contents: String?) {
        self.contents = contents
    }
}

// MARK: - ImageMessage
class ImageMessage: Codable {
    var image: UIImage?
    var contents: String?
    var imgHeight: Double?
    var imgWidth: Double?
    
    enum CodingKeys: String, CodingKey {
        case contents
        case imgHeight
        case imgWidth
    }

    init(image: UIImage? = nil, contents: String?, imgHeight: Double?, imgWidth: Double?) {
        self.image = image
        self.contents = contents
        self.imgHeight = imgHeight
        self.imgWidth = imgWidth
    }
}

