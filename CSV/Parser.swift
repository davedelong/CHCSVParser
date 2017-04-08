//
//  CSVParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public final class Parser {
    
    public enum Disposition: Equatable {
        case `continue`
        case cancel
        case error(Parser.Error)
        
        public static func ==(lhs: Disposition, rhs: Disposition) -> Bool {
            switch (lhs, rhs) {
                case (.continue, .continue): return true
                case (.cancel, .cancel): return true
                case (.error(let l), .error(let r)): return l == r
                default: return false
            }
        }
        
        public var error: Parser.Error? {
            guard case let .error(e) = self else { return nil }
            return e
        }
    }
    
    public struct Configuration {
        
        public let delimiter: Character
        public let recordTerminators: Set<Character>
        
        public var recognizeBackslashAsEscape = false
        public var sanitizeFields = false
        public var recognizeComments = false
        public var trimWhitespace = false
        public var recognizeLeadingEqualSign = false
        
        public var onBeginDocument: (Void) -> Disposition = { _ in return .continue }
        public var onEndDocument: (CSV.Progress, Parser.Error?) -> Void = { _ in }
        
        public var onBeginLine: (UInt, CSV.Progress) -> Disposition = { _ in return .continue }
        public var onEndLine: (UInt, CSV.Progress) -> Disposition = { _ in return .continue }
        
        public var onReadField: (String, UInt, UInt, CSV.Progress) -> Disposition = { _ in return .continue }
        public var onReadComment: (String, CSV.Progress) -> Disposition = { _ in return .continue }
        
        public init(delimiter d: Character = ",", recordTerminators: Set<Character> = Character.Newlines) {
            self.delimiter = d
            self.recordTerminators = recordTerminators
        }
        
    }
    
    private let configuration: Configuration
    private let sequence: AnySequence<Character>
    
    public init<S: Sequence>(characters: S, configuration: Configuration) where S.Iterator.Element == Character {
        self.sequence = AnySequence<Character>({ characters.makeIterator() })
        self.configuration = configuration
    }
    
    public convenience init(string: String, configuration: Configuration = Configuration()) {
        self.init(characters: string.characters, configuration: configuration)
    }
    
    public func parse() throws {
        if (configuration.delimiter == Character.Equal && configuration.recognizeLeadingEqualSign) ||
            (configuration.delimiter == Character.Backslash && configuration.recognizeBackslashAsEscape) ||
            (configuration.delimiter == Character.Octothorpe && configuration.recognizeComments) ||
            configuration.recordTerminators.contains(configuration.delimiter) || configuration.delimiter == Character.DoubleQuote {
                
            throw Parser.Error(kind: .illegalDelimiter(configuration.delimiter), line: nil, field: nil, progress: CSV.Progress())
        }
        
        let documentParser = _DocumentParser()
        let stream = CharacterIterator(iterator: sequence.makeIterator())
        
        let state = State(configuration: configuration, characterIterator: stream)
        let disposition = documentParser.parse(state)
        
        if let error = disposition.error {
            throw error
        }
    }
    
}
