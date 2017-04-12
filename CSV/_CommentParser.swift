//
//  CommentParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

internal struct _CommentParser: _Parser {
    
    func parse(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        
        guard stream.next() == Character.Octothorpe else {
            fatalError("Implementation flaw; starting to parse comment with no leading #")
        }
        
        var comment = "#"
        var sanitized = ""
        
        var isBackslashEscaped = false
        
        while let next = stream.peek() {
            if isBackslashEscaped == false {
                if next == Character.Backslash && state.configuration.recognizeBackslashAsEscape {
                    isBackslashEscaped = true
                    comment.append(next)
                    _ = stream.next()
                    
                } else if state.configuration.recordTerminators.contains(next) {
                    // don't consume the record terminator; that's handled by the document parser
                    break
                    
                } else {
                    comment.append(next)
                    sanitized.append(next)
                    _ = stream.next()
                }
            } else {
                isBackslashEscaped = false
                sanitized.append(next)
                comment.append(next)
                _ = stream.next()
            }
        }
        
        let progress = stream.progress(record: state.currentRecord, field: nil)
        if isBackslashEscaped == true {
            // technically this should only happen if the final character of the stream is a backslash, and we're allowing backslashes
            let error = Parser.Error(kind: .incompleteField, progress: progress)
            return .error(error)
        }
        
        let field = state.configuration.sanitizeFields ? sanitized : comment
        let final = state.configuration.trimWhitespace ? field.trimmingCharacters(in: .whitespacesAndNewlines) : field
        
        let disposition = state.configuration.onReadComment(final, progress)
        
        return disposition
        
    }
    
}
