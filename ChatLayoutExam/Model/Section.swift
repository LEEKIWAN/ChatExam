//
//  ChattingDateSection.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit
import DifferenceKit

struct Section: Hashable {
    var dateText: String
    var date: Date

    var cells: [RawMessage]
    
}

extension Section: DifferentiableSection {
    
    var differenceIdentifier: String {
        return dateText
    }
    
    func isContentEqual(to source: Section) -> Bool {
        return dateText == source.dateText
    }
    
    public var elements: [RawMessage] {
        return cells
    }
    
    public init<C: Swift.Collection>(source: Section, elements: C) where C.Element == RawMessage {
        self.init(dateText: source.dateText, date: source.date, cells: Array(elements))
    }


}
