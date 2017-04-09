//
//  DocumentParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal struct _DocumentParser: _Parser {
    let recordParser = _RecordParser()
    
    func parse(_ state: Parser.State) -> Parser.Disposition {
        let stream = state.characterIterator
        
        var disposition = state.configuration.onBeginDocument()
        
        while disposition == .continue && stream.peek() != nil {
            disposition = recordParser.parse(state)
            
            // if there are more characters to be read, make sure it's a record terminator
            if disposition == .continue && stream.peek() != nil {
                state.currentRecord += 1 // move to the next 0-based record
            }
        }
        
        let progress = stream.progress(record: state.currentRecord)
        state.configuration.onEndDocument(progress, disposition.error)
        return disposition
    }
}
