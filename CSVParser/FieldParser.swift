//
//  FieldParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

struct FieldParser {
    
    func parse(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration, line: UInt, index: UInt) throws -> Bool {
        guard let peek = stream.peek() else { return false }
        
        // there are more characters
        
        if peek == configuration.delimiter || peek.isNewline {
            configuration.onReadField?(field: "", index: index)
            return true
        }
        
        // consume the leading whitespace
        let leadingWS = parseWhitespace(stream, configuration: configuration)
        
        let field: String
        if stream.peek() == Character.DoubleQuote {
            // parse an escaped field
            field = try parseEscapedField(stream, configuration: configuration, line: line, index: index)
            
        } else if configuration.recognizeLeadingEqualSign && stream.peek() == Character.Equal && stream.peek(1) == Character.DoubleQuote {
            // consume the equal
            stream.next()
            //parse an escaped field
            field = try parseEscapedField(stream, configuration: configuration, line: line, index: index)
            
        } else {
            // parse an unescaped field
            field = try parseUnescapedField(stream, configuration: configuration, line: line, index: index)
        }
        
        let trailingWS = parseWhitespace(stream, configuration: configuration)
        
        // restore the whitespace around the field
        
        let final = configuration.trimWhitespace ? field.trim() : leadingWS + field + trailingWS
        configuration.onReadField?(field: final, index: index)
        
        return true
    }
    
    func parseWhitespace(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration) -> String {
        var w = ""
        while let peek = stream.peek() where peek.isWhitespace && peek != configuration.delimiter {
            w.append(peek)
            stream.next()
        }
        return w
    }
    
    func parseUnescapedField(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration, line: UInt, index: UInt) throws -> String {
        var field = ""
        var sanitized = ""
        
        var isBackslashEscaped = false
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                if next == Character.Backslash && configuration.recognizeBackslashAsEscape {
                    field.append(next)
                    stream.next()
                    isBackslashEscaped = true
                } else if next.isNewline || next == configuration.delimiter {
                    break
                } else {
                    field.append(next)
                    sanitized.append(next)
                    stream.next()
                }
            } else {
                isBackslashEscaped = false
                field.append(next)
                sanitized.append(next)
                stream.next()
            }
        }
        
        let next = stream.peek()
        if next == nil || next == configuration.delimiter || (next?.isNewline ?? false) {
            return configuration.sanitizeFields ? sanitized : field
        }
        
        throw CSVError(kind: .UnexpectedFieldTerminator, line: line, field: index, characterIndex: stream.currentIndex)
    }
    
    func parseEscapedField(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration, line: UInt, index: UInt) throws -> String {
        var field = "\""
        var sanitized = ""
        
        assert(stream.next() == Character.DoubleQuote, "Unexpected character opening escaped field")
        var isBackslashEscaped = false
        
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                
                if next == Character.Backslash && configuration.recognizeBackslashAsEscape {
                    isBackslashEscaped = true
                    stream.next()
                    field.append(next)
                } else if next == Character.DoubleQuote && stream.peek(1) == Character.DoubleQuote {
                    sanitized.append(Character.DoubleQuote)
                    field.append(Character.DoubleQuote); field.append(Character.DoubleQuote)
                    stream.next()
                    stream.next()
                } else if next == Character.DoubleQuote {
                    // quote that is NOT followed by another quote
                    // this is the closing field quote
                    break
                } else {
                    field.append(next)
                    sanitized.append(next)
                    stream.next()
                }
                
            } else {
                field.append(next)
                sanitized.append(next)
                
                isBackslashEscaped = false
                stream.next() // consume the character
            }
        }
        
        if stream.peek() == Character.Backslash {
            stream.next()
            if configuration.sanitizeFields {
                return sanitized
            } else {
                return field
            }
        } else {
            let actual: String
            if let n = stream.peek() {
                actual = String(n)
            } else {
                actual = "nothing"
            }
            let description = "Unexpected field terminator. Expected \" but got \(actual)"
            let error = NSError(domain: "com.davedelong.chcsvparser", code: 1, userInfo: [NSLocalizedDescriptionKey: description,
                "line": line,
                "field": index,
                "characterIndex": stream.currentIndex])
            throw error
        }
    }
}
