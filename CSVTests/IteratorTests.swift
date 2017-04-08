//
//  IteratorTests.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/23/15.
//
//

import XCTest
import CSV

class IteratorTests: XCTestCase {
    
    fileprivate func _testString(_ string: String, file: StaticString = #file, line: UInt = #line, function: String = #function) {
        
        let allEncodings = String.availableStringEncodings
        
        for encoding in allEncodings {
            let name = String.localizedName(of: encoding)
            
            guard string.canBeConverted(to: encoding) else {
                print("\t~~Cannot convert to \(name) (\(encoding))")
                continue
            }
            
            guard let data = string.data(using: encoding, allowLossyConversion: false) else {
                XCTFail("Failed to produce data for encoding \(name) (\(encoding))", file: file, line: line)
                continue
            }
            let url = temporaryFile("\(encoding).bin", function: function)
            guard (try? data.write(to: url, options: [.atomic])) != nil else {
                XCTFail("Failed to write data to file for encoding \(name) (\(encoding))", file: file, line: line)
                continue
            }
            
            let sequence = FileSequence(file: url, encoding: encoding)
            
            let message = String(format: "Failed to correctly read with encoding \(name) (%x)", encoding.rawValue)
            guard XCTAssertEqualSequences(sequence, string.characters, message, file: file, line: line) else { continue }
            
            print("\tCorrectly parsed \(name) (\(encoding))")
        }
    }
    
    func testUTF8Stream() {
        
        guard let csvFile = resource("Issue64", type: "csv") else { return }
        
        guard let contents = XCTAssertNoThrows(try String(contentsOf: csvFile, encoding: .utf8)) else { return }
        
        let sequence = FileSequence(file: csvFile, encoding: .utf8)
        
        _ = XCTAssertEqualSequences(sequence, contents.characters)
    }
    
    func testEncodingsForComplexString() {
        let complexString = "+∋∎⨋⨊∾≑〄♿︎☢﷼€➔↛↠➣⇻⤀ヿ㎆㌞№®℟καβγ㉟̊㉓⒕⃠🎀🎁🎂🎃🎄🎋🇦🇫🇦🇹🇧🇳🇪🇬🇬🇶🇮🇪🇬🇳🇵🇦🇵🇼ÀẨẮḘȆĲⱢɌỒŨỤăẳễƌįìóŏṽȹ̀"
        _testString(complexString)
    }
    
    func testEncodingsForSimpleString() {
        let simpleString = "Hello, world!"
        _testString(simpleString)
    }
    
    func testLargeFile() {
        
        guard let file = resource("Issue79") else {
            XCTFail("Cannot load resource")
            return
        }
        
        let sequence = FileSequence(file: file, encoding: .utf8)
        guard let contents = XCTAssertNoThrows(try String(contentsOf: file, encoding: .utf8)) else { return }
        
        _ = XCTAssertEqualSequences(sequence, contents.characters)
    }
    
}
