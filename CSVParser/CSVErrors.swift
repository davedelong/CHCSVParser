//
//  CSVErrors.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public struct CSVError: ErrorType {
    
    public enum Kind {
        case UnexpectedRecordTerminator
        case UnexpectedFieldTerminator
        case UnexpectedDelimiter
    }
    
    public let kind: Kind
    public let line: UInt
    public let field: UInt
    public let characterIndex: UInt
    
}
