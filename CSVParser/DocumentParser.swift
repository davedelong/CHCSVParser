//
//  DocumentParser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal struct DocumentParser {
    let recordParser = RecordParser()
    
    func parse<G: GeneratorType>(stream: CharacterStream<G>, configuration: CSVParserConfiguration) throws {
        let disposition = configuration.onBeginDocument?() ?? .Continue
        
        guard disposition == .Continue else {
            configuration.onEndDocument?(stream.progress())
            return
        }
        
        var currentLine: UInt = 0
        while stream.peek() != nil {
            let recordDisposition = try recordParser.parse(stream, configuration: configuration, line: currentLine)
            if recordDisposition == .Cancel { break }
            
            currentLine++
            
            if let peek = stream.peek() {
                guard configuration.recordTerminators.contains(peek) else {
                    throw CSVParserError(kind: .UnexpectedRecordTerminator, line: currentLine, field: 0, progress: stream.progress())
                }
            }
            
            stream.next() // consume the newline
        }
        
        configuration.onEndDocument?(stream.progress())
    }
}
