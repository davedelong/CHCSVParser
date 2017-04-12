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
        
        var disposition = state.configuration.onBeginRecord(stream.progress(record: state.currentRecord))
        
        if stream.peek() == Character.Octothorpe && state.configuration.recognizeComments {
            disposition = commentParser.parse(state)
        } else {
            disposition = parseRecord(state)
        }
        
        let endDisposition = state.configuration.onEndRecord(stream.progress(record: state.currentRecord))
        if disposition == .continue { disposition = endDisposition }
        return disposition
    }
    
    private func parseRecord(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        
        var disposition: Parser.Disposition = .continue
        
        repeat {
            disposition = fieldParser.parse(state)
            
            if let peek = stream.peek() {
                if peek == state.configuration.delimiter {
                    // there are more fields
                    _ = stream.next() // consume the delimiter
                    state.currentField += 1
                } else if state.configuration.recordTerminators.contains(peek) {
                    // we've reached the end of the record
                    // don't consume the record terminator; that's handled by the document parser
                    
                    break // break out of the field-parsing loop
                } else {
                    // not a field delimiter, and not a record terminator
                    let error = Parser.Error(kind: .unexpectedDelimiter(peek), progress: stream.progress(record: state.currentRecord, field: state.currentField))
                    disposition = .error(error)
                }
            } else {
                break
            }
        } while disposition == .continue
        
        return disposition
    }
}
