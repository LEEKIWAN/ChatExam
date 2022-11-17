//
//  FileManager.swift
//  ChatLayoutExam
//
//  Created by 이기완 on 2022/11/17.
//

import Foundation

class FileManager {
        
    static func readLocalFile(fileName: String, extensionType: String) -> Data? {
        guard let fileLocation = Bundle.main.url(forResource: fileName, withExtension: extensionType) else { return nil }
                
        do {
            let data = try Data(contentsOf: fileLocation)
            return data
        } catch {
            return nil
        }
    }
}
