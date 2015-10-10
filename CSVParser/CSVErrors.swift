//
//  CSVErrors.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public struct CSVParserError: ErrorType {
    
    public enum Kind {
        case IllegalDelimiter
        case UnexpectedRecordTerminator
        case UnexpectedFieldTerminator
        case UnexpectedDelimiter
        case IncompleteField
        case IllegalNumberOfFields
    }
    
    public let kind: Kind
    public let line: UInt?
    public let field: UInt?
    public let progress: CSVProgress
    
}
