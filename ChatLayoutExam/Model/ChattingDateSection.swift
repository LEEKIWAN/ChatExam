//
//  ChattingDateSection.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit
import DifferenceKit

struct ChattingDateSection: Differentiable {
    
    var dateText: String
    var date: Date

    var differenceIdentifier: String {
        return dateText
    }
    
    func isContentEqual(to source: ChattingDateSection) -> Bool {
        return dateText == dateText
    }
}
