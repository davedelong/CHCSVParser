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
            
        while disposition == .continue {
            disposition = recordParser.parse(state)
            state.currentRecord += 1 // move to the next 0-based record
            
            if stream.peek() == nil {
                state.currentRecord -= 1
                break
            }
        }
        
        let progress = stream.progress(record: state.currentRecord)
        state.configuration.onEndDocument(progress, disposition.error)
        return disposition
    }
}
