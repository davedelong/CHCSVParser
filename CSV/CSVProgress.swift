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
    
    public init(bytesRead: UInt = 0, charactersRead: UInt = 0) {
        self.bytesRead = bytesRead
        self.charactersRead = charactersRead
    }
    
    public static func ==(lhs: Progress, rhs: Progress) -> Bool {
        return lhs.bytesRead == rhs.bytesRead && lhs.charactersRead == rhs.charactersRead
    }
}
