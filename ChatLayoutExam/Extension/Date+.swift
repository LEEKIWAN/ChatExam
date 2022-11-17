//
//  Date+.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import UIKit

extension Date {
    
    func utcToDeviceLocal(format: String) -> String? {
        let timezone = TimeZone.current
        let seconds = TimeInterval(timezone.secondsFromGMT(for: self))
        let date = Date(timeInterval: seconds, since: self)
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
}


extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter
    }()
}


