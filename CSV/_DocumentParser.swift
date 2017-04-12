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
            if state.currentRecord > 0 {
                guard let peek = stream.peek(), state.configuration.recordTerminators.contains(peek) else {
                    fatalError("Starting a subsequent record, but no record terminator??")
                }
                _ = stream.next()
            }
            
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
