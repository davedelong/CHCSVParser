//
//  CSVParserTests.swift
//  CSVParserTests
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
@testable import CSV

class CSVParserTests: XCTestCase {
    
    func testEmpty() { }
    
    // most of the parser functionality testing happens as part of the ScenarioTests
    
    // MARK: Testing First Line as Keys
    
    /*
    func testOrderedDictionary() {
        let record: Record = [FIELD1: FIELD1, FIELD2: FIELD2, FIELD3: FIELD3]
        let expected = [FIELD1, FIELD2, FIELD3]
        XCTAssertEqual(record.fields.flatMap { $0.key }, expected)
        
        XCTAssertEqual(record[0]?.value, FIELD1, "Unexpected field")
        XCTAssertEqual(record[1]?.value, FIELD2, "Unexpected field")
        XCTAssertEqual(record[2]?.value, FIELD3, "Unexpected field")
        
        XCTAssertEqual(record[FIELD1]?.value, FIELD1, "Unexpected field")
        XCTAssertEqual(record[FIELD2]?.value, FIELD2, "Unexpected field")
        XCTAssertEqual(record[FIELD3]?.value, FIELD3, "Unexpected field")
    }
    
    func testFirstLineAsKeys() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE+FIELD1+COMMA+FIELD2+COMMA+FIELD3
        let expected: Array<Record> = [
            [FIELD1: FIELD1, FIELD2: FIELD2, FIELD3: FIELD3]
        ]
        
        guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(useFirstRecordAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed.records, expected)
    }
    
    func testFirstLineAsKeys_SingleLine() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE
        let expected: Array<Record> = []
        
        guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(useFirstRecordAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed.records, expected)
        
        let csv2 = FIELD1+COMMA+FIELD2+COMMA+FIELD3
        guard let parsed2 = XCTAssertNoThrows(try csv2.delimitedComponents(useFirstRecordAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed2.records, expected)
    }
    
    func testFirstLineAsKeys_MismatchedFieldCount() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE+FIELD1+COMMA+FIELD2+COMMA+FIELD3+COMMA+FIELD1
        
        XCTAssertThrows(try csv.delimitedComponents(useFirstRecordAsKeys: true))
    }
    
    // MARK: Testing Valid Delimiters
    
    func testAllowedDelimiter_Octothorpe() {
        let csv = FIELD1+OCTOTHORPE+FIELD2+OCTOTHORPE+FIELD3
        guard let actual = XCTAssertNoThrows(try csv.delimitedComponents(CSV.Parser.Configuration(delimiter: "#"))) else { return }
        let expected: Array<Record> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = XCTAssertEqualRecordArrays(actual.records, expected)
    }
    
    func testDisallowedDelimiter_Octothorpe() {
        let csv = FIELD1+OCTOTHORPE+FIELD2+OCTOTHORPE+FIELD3
        
        var config = CSV.Parser.Configuration(delimiter: "#")
        config.recognizeComments = true
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testAllowedDelimiter_Backslash() {
        let csv = FIELD1+BACKSLASH+FIELD2+BACKSLASH+FIELD3
        let expected: Array<Record> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = parse(csv, expected, CSV.Parser.Configuration(delimiter: "\\"))
    }
    
    func testDisallowedDelimiter_Backslash() {
        let csv = FIELD1+BACKSLASH+FIELD2+BACKSLASH+FIELD3
        
        var config = CSV.Parser.Configuration(delimiter: "\\")
        config.recognizeBackslashAsEscape = true
        
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testAllowedDelimiter_Equal() {
        let csv = FIELD1+EQUAL+FIELD2+EQUAL+FIELD3
        let expected: Array<Record> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = parse(csv, expected, CSV.Parser.Configuration(delimiter: "="))
    }
    
    func testDisallowedDelimiter_Equal() {
        let csv = FIELD1+EQUAL+FIELD2+EQUAL+FIELD3
        
        var config = CSV.Parser.Configuration(delimiter: "=")
        config.recognizeLeadingEqualSign = true
        
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    // MARK: Testing Record Terminators
    
    func testCustomRecordTerminators() {
        let csv = FIELD1+COMMA+FIELD2+OCTOTHORPE+FIELD1+COMMA+FIELD2+COMMA+FIELD3
        let expected: Array<Record> = [[FIELD1, FIELD2], [FIELD1, FIELD2, FIELD3]]
        
        let config = CSV.Parser.Configuration(recordTerminators: ["#"])
        _ = parse(csv, expected, config)
    }
    
    // MARK: Testing Leading Equal
    
    func testLeadingEqual() {
        let csv = FIELD1+COMMA+EQUAL+QUOTED_FIELD2+COMMA+EQUAL+QUOTED_FIELD3
        let expected: Array<Record> = [[FIELD1, EQUAL+QUOTED_FIELD2, EQUAL+QUOTED_FIELD3]]
        
        var config = CSV.Parser.Configuration()
        config.recognizeLeadingEqualSign = true
        _ = parse(csv, expected, config)
    }
    
    func testSanitizedLeadingEqual() {
        let csv = FIELD1+COMMA+EQUAL+QUOTED_FIELD2+COMMA+EQUAL+QUOTED_FIELD3
        let expected: Array<Record> = [[FIELD1, FIELD2, FIELD3]]
        
        var config = CSV.Parser.Configuration()
        config.recognizeLeadingEqualSign = true
        config.sanitizeFields = true
        _ = parse(csv, expected, config)
    }
    
    // MARK: Testing Cancellation
    
    func testDocumentCancellation() {
        let csv = FIELD1+COMMA+FIELD2
        
        var config = CSV.Parser.Configuration()
        config.onBeginDocument = {
            return .cancel
        }
        config.onBeginRecord = { _ in
            XCTFail("Should not begin line")
            return .cancel
        }
        
        let parser = CSV.Parser(characters: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testBeginLineCancellation() {
        let csv = FIELD1+COMMA+FIELD2
        
        var config = CSV.Parser.Configuration()
        config.onBeginRecord = { _ in
            return .cancel
        }
        config.onReadField = { _ in
            XCTFail("Should not read field")
            return .cancel
        }
        
        let parser = CSV.Parser(characters: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testEndLineCancellation() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSV.Parser.Configuration()
        var beginLineCount = 0
        
        config.onBeginRecord = { _ in
            beginLineCount += 1
            return .continue
        }
        config.onEndRecord = { _ in
            return .cancel
        }
        
        let parser = CSV.Parser(characters: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
        XCTAssertEqual(beginLineCount, 1)
    }
    
    func testFieldCancellation() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSV.Parser.Configuration()
        var readFieldCount = 0
        
        config.onReadField = { _ in
            readFieldCount += 1
            return .cancel
        }
        
        let parser = CSV.Parser(characters: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
        XCTAssertEqual(readFieldCount, 1)
    }
    
    func testCommentCancellation() {
        let csv = OCTOTHORPE+FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSV.Parser.Configuration()
        config.recognizeComments = true
        
        config.onReadField = { _ in
            XCTFail("Should not read field")
            return .cancel
        }
        config.onReadComment = { _ in
            return .cancel
        }
        
        let parser = CSV.Parser(characters: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    */
}
