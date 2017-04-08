//
//  FieldParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

struct _FieldParser: _Parser {
    
    func parse(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        // check for more characters
        guard let peek = stream.peek() else {
            // no characters; report an empty field
            return state.configuration.onReadField("", state.currentLine, state.currentField, stream.progress())
        }
        
        if peek == state.configuration.delimiter || state.configuration.recordTerminators.contains(peek) {
            // field terminator; report an empty field
            return state.configuration.onReadField("", state.currentLine, state.currentField, stream.progress())
        }
        
        // consume the leading whitespace
        let leadingWS = parseWhitespace(state)
        
        let field: String
        do {
            if stream.peek() == Character.DoubleQuote {
                // parse an escaped field
                field = try parseEscapedField(state)
                
            } else if state.configuration.recognizeLeadingEqualSign && stream.peek() == Character.Equal && stream.peek(1) == Character.DoubleQuote {
                //parse an escaped field
                field = try parseEscapedField(state)
                
            } else {
                // parse an unescaped field
                field = try parseUnescapedField(state)
            }
        } catch let e as Parser.Error {
            return .error(e)
        } catch let other {
            fatalError("Unexpected error parsing field: \(other)")
        }
        
        let trailingWS = parseWhitespace(state)
        
        // restore the whitespace around the field
        let final = state.configuration.trimWhitespace ? field.trimmingCharacters(in: .whitespaces) : leadingWS + field + trailingWS
        
        return state.configuration.onReadField(final, state.currentLine, state.currentField, stream.progress())
    }
    
    func parseWhitespace(_ state: Parser.State) -> String {
        let stream = state.characterIterator
        var w = ""
        while let peek = stream.peek() , Character.Whitespaces.contains(peek) && peek != state.configuration.delimiter {
            w.append(peek)
            _ = stream.next()
        }
        return w
    }
    
    func parseUnescapedField(_ state: Parser.State) throws -> String {
        let stream = state.characterIterator
        
        var field = ""
        var sanitized = ""
        
        var isBackslashEscaped = false
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                if next == Character.Backslash && state.configuration.recognizeBackslashAsEscape {
                    field.append(next)
                    _ = stream.next()
                    isBackslashEscaped = true
                } else if state.configuration.recordTerminators.contains(next) || next == state.configuration.delimiter {
                    break
                } else {
                    field.append(next)
                    sanitized.append(next)
                    _ = stream.next()
                }
            } else {
                isBackslashEscaped = false
                field.append(next)
                sanitized.append(next)
                _ = stream.next()
            }
        }
        
        if isBackslashEscaped == true {
            throw Parser.Error(kind: .incompleteField, line: state.currentLine, field: state.currentField, progress: stream.progress())
        }
        
        if let next = stream.peek() {
            guard next == state.configuration.delimiter || state.configuration.recordTerminators.contains(next) else {
                fatalError("Implementation flaw; Unexpectedly finished parsing unescaped field")
            }
        }
        // end of field
        return state.configuration.sanitizeFields ? sanitized : field
    }
    
    func parseEscapedField(_ state: Parser.State) throws -> String {
        let stream = state.characterIterator
        
        var raw = ""
        var sanitized = ""
        
        if state.configuration.recognizeLeadingEqualSign && stream.peek() == Character.Equal {
            _ = stream.next()
            raw.append(Character.Equal)
        }
        
        guard let next = stream.next(), next == Character.DoubleQuote else {
            fatalError("Unexpected character opening escaped field")
        }
        
        raw.append(Character.DoubleQuote)
        var isBackslashEscaped = false
        
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                
                if next == Character.Backslash && state.configuration.recognizeBackslashAsEscape {
                    isBackslashEscaped = true
                    _ = stream.next()
                    raw.append(next)
                    
                } else if next == Character.DoubleQuote && stream.peek(1) == Character.DoubleQuote {
                    sanitized.append(Character.DoubleQuote)
                    raw.append(Character.DoubleQuote); raw.append(Character.DoubleQuote)
                    _ = stream.next()
                    _ = stream.next()
                    
                } else if next == Character.DoubleQuote {
                    // quote that is NOT followed by another quote
                    // this is the closing field quote
                    break
                    
                } else {
                    raw.append(next)
                    sanitized.append(next)
                    _ = stream.next()
                }
                
            } else {
                raw.append(next)
                sanitized.append(next)
                
                isBackslashEscaped = false
                _ = stream.next() // consume the character
            }
        }
        
        guard isBackslashEscaped == false else {
            throw Parser.Error(kind: .incompleteField, line: state.currentLine, field: state.currentField, progress: stream.progress())
        }
        
        guard stream.peek() == Character.DoubleQuote else {
            throw Parser.Error(kind: .unexpectedFieldTerminator(stream.peek()), line: state.currentLine, field: state.currentField, progress: stream.progress())
        }
        
        raw.append(Character.DoubleQuote)
        _ = stream.next()
        
        return state.configuration.sanitizeFields ? sanitized : raw
    }
}
