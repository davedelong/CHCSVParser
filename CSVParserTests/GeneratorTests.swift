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
    
    private func _testString(string: String, file: String = __FILE__, line: UInt = __LINE__, function: String = __FUNCTION__) {
        
        let allEncodings = String.availableStringEncodings()
        
        for encoding in allEncodings {
            let name = String.localizedNameOfStringEncoding(encoding)
            
            guard string.canBeConvertedToEncoding(encoding) else {
                print("\t~~Cannot convert to \(name) (\(encoding))")
                continue
            }
            
            guard let data = string.dataUsingEncoding(encoding, allowLossyConversion: false) else {
                XCTFail("Failed to produce data for encoding \(name) (\(encoding))", file: file, line: line)
                continue
            }
            let url = temporaryFile("\(encoding).bin", function: function)
            guard data.writeToURL(url, atomically: true) else {
                XCTFail("Failed to write data to file for encoding \(name) (\(encoding))", file: file, line: line)
                continue
            }
            
            let sequence = FileSequence(file: url, encoding: encoding)
            
            let message = String(format: "Failed to correctly read with encoding \(name) (%x)", encoding)
            guard XCTAssertEqualSequences(sequence, string.characters, message, file: file, line: line) else { continue }
            
            print("\tCorrectly parsed \(name) (\(encoding))")
        }
    }
    
    func testUTF8Stream() {
        
        guard let csvFile = resource("Issue64", type: "csv") else { return }
        
        guard let contents = XCTAssertNoThrows(try String(contentsOfURL: csvFile, encoding: NSUTF8StringEncoding)) else { return }
        
        let sequence = FileSequence(file: csvFile, encoding: NSUTF8StringEncoding)
        
        XCTAssertEqualSequences(sequence, contents.characters)
    }
    
    func testEncodingsForComplexString() {
        let complexString = "+∋∎⨋⨊∾≑〄♿︎☢﷼€➔↛↠➣⇻⤀ヿ㎆㌞№®℟καβγ㉟̊㉓⒕⃠🎀🎁🎂🎃🎄🎋🇦🇫🇦🇹🇧🇳🇪🇬🇬🇶🇮🇪🇬🇳🇵🇦🇵🇼ÀẨẮḘȆĲⱢɌỒŨỤăẳễƌįìóŏṽȹ̀"
        _testString(complexString)
    }
    
    func testEncodingsForSimpleString() {
        let simpleString = "Hello, world!"
        _testString(simpleString)
    }
    
}
