//
//  CSVProgress.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

public struct Progress: Equatable {
    public let bytesRead: UInt
    public let charactersRead: UInt
    public let line: UInt?
    public let field: UInt?
    
    public init(bytesRead: UInt = 0, charactersRead: UInt = 0, line: UInt? = nil, field: UInt? = nil) {
        self.bytesRead = bytesRead
        self.charactersRead = charactersRead
        self.line = line
        self.field = field
    }
    
    public static func ==(lhs: Progress, rhs: Progress) -> Bool {
        guard lhs.bytesRead == rhs.bytesRead && lhs.charactersRead == rhs.charactersRead else { return false }
        
        if let lLine = lhs.line, let rLine = rhs.line {
            guard lLine == rLine else { return false }
        }
        
        if let lField = lhs.field, let rField = rhs.field {
            guard lField == rField else { return false }
        }
        
        return true
    }
}
