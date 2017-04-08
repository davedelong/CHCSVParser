//
//  Parser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

internal final class ParserState {
    let configuration: CSVParser.Configuration
    var characterIterator: CharacterIterator
    var currentLine: UInt = 0
    var currentField: UInt = 0
    
    init(configuration: CSVParser.Configuration, characterIterator: CharacterIterator) {
        self.configuration = configuration
        self.characterIterator = characterIterator
    }
}

internal protocol Parser {
    
    func parse(_ state: ParserState) -> CSVParsingDisposition
    
}
