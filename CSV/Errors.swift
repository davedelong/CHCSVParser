//
//  CSVErrors.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public extension Parser {
    
    public struct Error: Swift.Error, Equatable {
        
        public enum Kind: Equatable {
            case illegalRecordTerminator
            case illegalDelimiter(Character)
            case unexpectedFieldTerminator(Character?)
            case unexpectedDelimiter(Character)
            case incompleteField
            case illegalNumberOfFields
            
            public static func ==(lhs: Kind, rhs: Kind) -> Bool {
                switch (lhs, rhs) {
                    case (.illegalRecordTerminator, .illegalRecordTerminator): return true
                    case (.illegalDelimiter(let l), .illegalDelimiter(let r)): return l == r
                    case (.unexpectedFieldTerminator(let l), .unexpectedFieldTerminator(let r)): return l == r
                    case (.unexpectedDelimiter(let l), .unexpectedDelimiter(let r)): return l == r
                    case (.incompleteField, .incompleteField): return true
                    case (.illegalNumberOfFields, .illegalNumberOfFields): return true
                    default: return false
                }
            }
        }
        
        public let kind: Kind
        public let progress: CSV.Progress
        public var record: UInt? { return progress.record }
        public var field: UInt? { return progress.field }
        
        public var character: Character? {
            switch kind {
                case .illegalDelimiter(let c): return c
                case .unexpectedFieldTerminator(let c): return c
                case .unexpectedDelimiter(let c): return c
                default: return nil
            }
        }
        
        public static func ==(lhs: Parser.Error, rhs: Parser.Error) -> Bool {
            guard lhs.kind == rhs.kind else { return false }
            guard lhs.progress == rhs.progress else { return false }
            
            return true
        }
    }
    
}

public extension Writer {

    public struct Error: Swift.Error, Equatable {
        
        public enum Kind {
            case invalidOutputStream
            case illegalDelimiter
            case illegalRecordTerminator
            case invalidRecord
            case missingField(String)
        }
        
        public let kind: Kind
        
        public static func ==(lhs: Writer.Error, rhs: Writer.Error) -> Bool {
            switch (lhs.kind, rhs.kind) {
                case (.illegalDelimiter, .illegalDelimiter): return true
                case (.illegalRecordTerminator, .illegalRecordTerminator): return true
                case (.invalidRecord, .invalidRecord): return true
                case (.missingField(let l), .missingField(let r)): return l == r
                default: return false
            }
        }
        
    }

}
