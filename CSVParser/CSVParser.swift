//
//  CSVParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public enum ParsingDisposition {
    case Continue
    case Cancel
}

public struct CSVProgress {
    public let bytesRead: UInt
    public let charactersRead: UInt
    
    public init(bytesRead: UInt = 0, charactersRead: UInt = 0) {
        self.bytesRead = bytesRead
        self.charactersRead = charactersRead
    }
}

public struct CSVParserConfiguration {
    
    public let delimiter: Character
    
    public var recognizeBackslashAsEscape = false
    public var sanitizeFields = false
    public var recognizeComments = false
    public var trimWhitespace = false
    public var recognizeLeadingEqualSign = false
    
    public var onBeginDocument: (Void -> ParsingDisposition)? = nil
    public var onEndDocument: (CSVProgress -> Void)? = nil
    public var onBeginLine: ((UInt, CSVProgress) -> ParsingDisposition)? = nil
    public var onEndLine: ((UInt, CSVProgress) throws -> ParsingDisposition)? = nil
    public var onReadField: ((String, UInt, CSVProgress) -> ParsingDisposition)? = nil
    public var onReadComment: ((String, CSVProgress) -> ParsingDisposition)? = nil
    
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
                
            throw CSVError(kind: .IllegalDelimiter, line: nil, field: nil, progress: CSVProgress())
        }
        
        let documentParser = DocumentParser()
        let stream = PeekingGenerator(sequence: sequence)
        try documentParser.parse(stream, configuration: configuration)
    }
    
}
