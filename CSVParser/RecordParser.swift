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
    
    func parse<G: GeneratorType>(stream: CharacterStream<G>, configuration: CSVParserConfiguration, line: UInt) throws -> ParsingDisposition {
        guard stream.peek() != nil else { return .Continue }
        
        let recordDisposition: ParsingDisposition
        if stream.peek() == Character.Octothorpe && configuration.recognizeComments {
            recordDisposition = try parseComment(stream, configuration: configuration, line: line)
        } else {
            recordDisposition = try parseRecord(stream, configuration: configuration, line: line)
        }
        
        return recordDisposition
    }
    
    func parseRecord<G: GeneratorType>(stream: CharacterStream<G>, configuration: CSVParserConfiguration, line: UInt) throws -> ParsingDisposition {
        let beginDisposition = configuration.onBeginLine?(line, stream.progress()) ?? .Continue
        guard beginDisposition == .Continue else {
            _ = try configuration.onEndLine?(line, stream.progress())
            return beginDisposition
        }
        
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
            } else if configuration.recordTerminators.contains(next) {
                break
            } else {
                throw CSVError(kind: .UnexpectedDelimiter, line: line, field: currentField, progress: stream.progress())
            }
            
        }
        
        return try configuration.onEndLine?(line, stream.progress()) ?? .Continue
    }
    
    func parseComment<G: GeneratorType>(stream: CharacterStream<G>, configuration: CSVParserConfiguration, line: UInt) throws -> ParsingDisposition {
        let beginDisposition = configuration.onBeginLine?(line, stream.progress()) ?? .Continue
        guard beginDisposition == .Continue else {
            _ = try configuration.onEndLine?(line, stream.progress())
            return beginDisposition
        }
        
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
                } else if configuration.recordTerminators.contains(next) {
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
            throw CSVError(kind: .IncompleteField, line: nil, field: nil, progress: stream.progress())
        }
        
        let final: String
        switch (configuration.sanitizeFields, configuration.trimWhitespace) {
            case (true, true): final = sanitized.trim()
            case (true, false): final = sanitized
            case (false, true): final = comment.trim()
            case (false, false): final = comment
        }
        
        let commentDisposition = configuration.onReadComment?(final, stream.progress()) ?? .Continue
        let recordDisposition = try configuration.onEndLine?(line, stream.progress()) ?? .Continue
        
        return commentDisposition == .Cancel ? commentDisposition : recordDisposition
    }
}
