//
//  RecordParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal struct RecordParser {
    let fieldParser = FieldParser()
    
    func parse(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration, line: UInt) throws -> ParsingDisposition {
        guard stream.peek() != nil else { return .Continue }
        
        // there are more characters, which means there are more things to parse
        let beginLineDisposition = configuration.onBeginLine?(line: line) ?? .Continue
        guard beginLineDisposition == .Continue else {
            _ = try configuration.onEndLine?(line: line)
            return beginLineDisposition
        }
        
        let lineDisposition: ParsingDisposition
        if stream.peek() == Character.Octothorpe && configuration.recognizeComments {
            lineDisposition = try parseComment(stream, configuration: configuration)
            guard lineDisposition == .Continue else {
                _ = try configuration.onEndLine?(line: line)
                return lineDisposition
            }
        } else {
            lineDisposition = try parseRecord(stream, configuration: configuration, line: line)
        }
        
        let endLineDisposition = try configuration.onEndLine?(line: line) ?? .Continue
        
        return lineDisposition == .Cancel ? lineDisposition : endLineDisposition
    }
    
    func parseRecord(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration, line: UInt) throws -> ParsingDisposition {
        var currentField: UInt = 0
        while true {
            let fieldDisposition = try fieldParser.parse(stream, configuration: configuration, line: line, index: currentField)
            if fieldDisposition == .Cancel { return fieldDisposition }
            
            currentField++
            guard let next = stream.peek() else { break }
            
            // if the next character is a delimiter, consume it
            // if the next character is a newline, break
            // otherwise produce an error and break
            if next == configuration.delimiter {
                stream.next()
            } else if next.isNewline {
                break
            } else {
                throw CSVError(kind: .UnexpectedDelimiter, line: line, field: currentField, characterIndex: stream.currentIndex)
            }
            
        }
        
        return .Continue
    }
    
    func parseComment(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration) throws -> ParsingDisposition {
        guard stream.next() == Character.Octothorpe else {
            fatalError("Implementation flaw; starting to parse comment with no leading #")
        }
        var comment = "#"
        var sanitized = ""
        
        var isBackslashEscaped = false
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                if next == Character.Backslash && configuration.recognizeBackslashAsEscape {
                    isBackslashEscaped = true
                    comment.append(next)
                    stream.next()
                } else if next.isNewline {
                    break
                } else {
                    comment.append(next)
                    sanitized.append(next)
                    stream.next()
                }
            } else {
                isBackslashEscaped = false
                sanitized.append(next)
                comment.append(next)
                stream.next()
            }
        }
        
        if isBackslashEscaped == true {
            throw CSVError(kind: .IncompleteField, line: nil, field: nil, characterIndex: stream.currentIndex)
        }
        
        let final: String
        switch (configuration.sanitizeFields, configuration.trimWhitespace) {
            case (true, true): final = sanitized.trim()
            case (true, false): final = sanitized
            case (false, true): final = comment.trim()
            case (false, false): final = comment
        }
        
        return configuration.onReadComment?(comment: final) ?? .Continue
    }
}
