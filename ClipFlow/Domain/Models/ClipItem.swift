//
//  ClipItem.swift
//  ClipFlow
//
//  Created by Sajudin on 16/06/26.
//

import Foundation
import SwiftData

enum ClipType: String {
    case text = "text"
    case image = "image"
}

@Model
final class ClipItem {
    var content: String
    var timestamp: Date
    var typeRawValue: String?
    @Attribute(.externalStorage) var imageData: Data?
    
    var type: ClipType {
        if let raw = typeRawValue, let clipType = ClipType(rawValue: raw) {
            return clipType
        }
        return .text
    }
    
    init(content: String, timestamp: Date = Date(), type: ClipType = .text, imageData: Data? = nil) {
        self.content = content
        self.timestamp = timestamp
        self.typeRawValue = type.rawValue
        self.imageData = imageData
    }
}
