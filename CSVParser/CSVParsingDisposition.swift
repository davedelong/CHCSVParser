//
//  CSVParsingDisposition.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

public enum CSVParsingDisposition: Equatable {
    case `continue`
    case cancel
    case error(CSVParserError)
    
    public static func ==(lhs: CSVParsingDisposition, rhs: CSVParsingDisposition) -> Bool {
        switch (lhs, rhs) {
            case (.continue, .continue): return true
            case (.cancel, .cancel): return true
            case (.error(let l), .error(let r)): return l == r
            default: return false
        }
    }
    
    public var error: CSVParserError? {
        guard case let .error(e) = self else { return nil }
        return e
    }
}
