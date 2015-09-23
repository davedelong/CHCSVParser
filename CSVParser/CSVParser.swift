//
//  CSVParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public struct CSVParserConfiguration {
    
    public let delimiter: Character
    
    public var recognizeBackslashAsEscape = false
    public var sanitizeFields = false
    public var recognizeComments = false
    public var trimWhitespace = false
    public var recognizeLeadingEqualSign = false
    
    public var onBeginDocument: Optional<() -> Void> = nil
    public var onEndDocument: Optional<() -> Void> = nil
    public var onBeginLine: Optional<(line: UInt) -> Void> = nil
    public var onEndLine: Optional<(line: UInt) -> Void> = nil
    public var onReadField: Optional<(field: String, index: UInt) -> Void> = nil
    public var onReadComment: Optional<(comment: String) -> Void> = nil
    
    public init(delimiter d: Character = ",") {
        delimiter = d
    }
    
}

public class CSVParser<S: SequenceType where S.Generator.Element == Character> {
    
    private let configuration: CSVParserConfiguration
    private let sequence: S
    
    public init(characterSequence: S, configuration: CSVParserConfiguration) {
        self.sequence = characterSequence
        self.configuration = configuration
    }
    
    public func parse() throws {
        if (configuration.delimiter == Character.Equal && configuration.recognizeLeadingEqualSign) ||
            (configuration.delimiter == Character.Backslash && configuration.recognizeBackslashAsEscape) ||
            (configuration.delimiter == Character.Octothorpe && configuration.recognizeComments) ||
            configuration.delimiter.isNewline || configuration.delimiter == Character.DoubleQuote {
                
            throw CSVError(kind: .IllegalDelimiter, line: 0, field: 0, characterIndex: 0)
        }
        
        let documentParser = DocumentParser()
        let stream = PeekingGenerator(sequence: sequence)
        try documentParser.parse(stream, configuration: configuration)
    }
    
}
