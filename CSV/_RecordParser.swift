//
//  RecordParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal struct _RecordParser: _Parser {
    let fieldParser = _FieldParser()
    let commentParser = _CommentParser()
    
    func parse(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        state.currentField = 0
        
        if stream.peek() == Character.Octothorpe && state.configuration.recognizeComments {
            return commentParser.parse(state)
        } else {
            return parseRecord(state)
        }
    }
    
    private func parseRecord(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        
        var disposition = state.configuration.onBeginLine(state.currentLine, stream.progress())
        
        while disposition == .continue {
            disposition = fieldParser.parse(state)
            
            if let peek = stream.peek() {
                if peek == state.configuration.delimiter {
                    // there are more fields
                    _ = stream.next() // consume the delimiter
                    state.currentField += 1
                } else if state.configuration.recordTerminators.contains(peek) {
                    // we've reached the end of the record
                    _ = stream.next() // consume the record terminator
                    
                    break // break out of the field-parsing loop
                } else {
                    // not a field delimiter, and not a record terminator
                    let error = Parser.Error(kind: .unexpectedDelimiter(peek), line: state.currentLine, field: state.currentField, progress: stream.progress())
                    disposition = .error(error)
                }
            } else {
                break
            }
        }
        
        let endDisposition = state.configuration.onEndLine(state.currentLine, stream.progress())
        if disposition == .continue { disposition = endDisposition }
        return disposition
    }
}
