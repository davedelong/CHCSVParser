//
//  CSVProgress.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

public struct Progress: Equatable {
    public let byteCount: UInt
    public let characterCount: UInt
    public let record: UInt?
    public let field: UInt?
    
    public init(byteCount: UInt = 0, characterCount: UInt = 0, record: UInt? = nil, field: UInt? = nil) {
        self.byteCount = byteCount
        self.characterCount = characterCount
        self.record = record
        self.field = field
    }
    
    public static func ==(lhs: Progress, rhs: Progress) -> Bool {
        guard lhs.byteCount == rhs.byteCount && lhs.characterCount == rhs.characterCount else { return false }
        
        if let lRecord = lhs.record, let rRecord = rhs.record {
            guard lRecord == rRecord else { return false }
        }
        
        if let lField = lhs.field, let rField = rhs.field {
            guard lField == rField else { return false }
        }
        
        return true
    }
}
