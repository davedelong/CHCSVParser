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
    
    func parse(stream: PeekingGenerator<Character>, configuration: CSVParserConfiguration) throws {
        configuration.onBeginDocument?()
        
        var currentLine: UInt = 0
        while try recordParser.parse(stream, configuration: configuration, line: currentLine) {
            currentLine++
            guard let next = stream.peek() else { continue }
            guard next.isNewline else {
                throw CSVError(kind: .UnexpectedRecordTerminator, line: currentLine, field: 0, characterIndex: stream.currentIndex)
            }
            stream.next() // consume the newline
        }
        
        configuration.onEndDocument?()
    }
}
