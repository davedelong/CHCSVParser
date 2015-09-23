//
//  GeneratorTests.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/23/15.
//
//

import XCTest
import CSVParser

class GeneratorTests: XCTestCase {
    
    func testUTF8Stream() {
        
        guard let csvFile = resource("Issue64", type: "csv") else { return }
        
        guard let contents = XCTAssertNoThrows(try String(contentsOfURL: csvFile, encoding: NSUTF8StringEncoding)) else { return }
        
        let sequence = FileSequence(file: csvFile, encoding: NSUTF8StringEncoding)
        
        let actualCharacters = Array(contents.characters)
        let streamedCharacters = Array(sequence)
        
        XCTAssertEqual(streamedCharacters.count, actualCharacters.count)
        guard streamedCharacters.count == actualCharacters.count else { return }
        
        var characterIndex = 0
        for (s, a) in zip(streamedCharacters, actualCharacters) {
            XCTAssertEqual(s, a, "Expected \(a) but got \(s) at character index \(characterIndex)")
            guard s == a else { return }
            characterIndex++
        }
    }
    
}
