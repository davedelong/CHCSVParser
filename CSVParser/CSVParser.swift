//
//  CSVParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public final class CSVParser {
    
    public struct Configuration {
        
        public let delimiter: Character
        public let recordTerminators: Set<Character>
        
        public var recognizeBackslashAsEscape = false
        public var sanitizeFields = false
        public var recognizeComments = false
        public var trimWhitespace = false
        public var recognizeLeadingEqualSign = false
        
        public var onBeginDocument: (Void) -> CSVParsingDisposition = { _ in return .continue }
        public var onEndDocument: (CSVProgress, CSVParserError?) -> Void = { _ in }
        
        public var onBeginLine: (UInt, CSVProgress) -> CSVParsingDisposition = { _ in return .continue }
        public var onEndLine: (UInt, CSVProgress) -> CSVParsingDisposition = { _ in return .continue }
        
        public var onReadField: (String, UInt, UInt, CSVProgress) -> CSVParsingDisposition = { _ in return .continue }
        public var onReadComment: (String, CSVProgress) -> CSVParsingDisposition = { _ in return .continue }
        
        public init(delimiter d: Character = ",", recordTerminators: Set<Character> = Character.Newlines) {
            self.delimiter = d
            self.recordTerminators = recordTerminators
        }
        
    }
    
    private let configuration: Configuration
    private let sequence: AnySequence<Character>
    
    public init(characters: AnySequence<Character>, configuration: Configuration) {
        self.sequence = characters
        self.configuration = configuration
    }
    
    public convenience init<S: Sequence>(characterSequence: S, configuration: Configuration) where S.Iterator.Element == Character {
        let any = AnySequence<Character>({ characterSequence.makeIterator() })
        self.init(characters: any, configuration: configuration)
    }
    
    public func parse() throws {
        if (configuration.delimiter == Character.Equal && configuration.recognizeLeadingEqualSign) ||
            (configuration.delimiter == Character.Backslash && configuration.recognizeBackslashAsEscape) ||
            (configuration.delimiter == Character.Octothorpe && configuration.recognizeComments) ||
            configuration.recordTerminators.contains(configuration.delimiter) || configuration.delimiter == Character.DoubleQuote {
                
            throw CSVParserError(kind: .illegalDelimiter(configuration.delimiter), line: nil, field: nil, progress: CSVProgress())
        }
        
        let documentParser = DocumentParser()
        let stream = CharacterIterator(sequence: sequence)
        
        let state = ParserState(configuration: configuration, characterIterator: stream)
        let disposition = documentParser.parse(state)
        
        if let error = disposition.error {
            throw error
        }
    }
    
}
