//
//  Parser.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/20/16.
//
//

import Foundation

extension Parser {
    internal final class State {
        let configuration: Parser.Configuration
        var characterIterator: CharacterIterator
        var currentRecord: UInt = 0
        var currentField: UInt = 0
        
        init(configuration: Parser.Configuration, characterIterator: CharacterIterator) {
            self.configuration = configuration
            self.characterIterator = characterIterator
        }
    }
}
    
internal protocol _Parser {
    
    func parse(_ state: Parser.State) -> Parser.Disposition
    
}
