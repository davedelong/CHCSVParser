//
//  CSVParserTests.swift
//  CSVParserTests
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
@testable import CSVParser

class CSVParserTests: XCTestCase {
    
    func testSimple() {
        let csv = "\(Field1),\(Field2),\(Field3)"
        let expected: Array<CSVRecord> = [[Field1, Field2, Field3]]
        _ = parse(csv, expected)
    }
    
    func testSimpleUTF8() {
        let csv = "\(Field1),\(Field2),\(Field3),\(UTFField4)\n\(Field1),\(Field2),\(Field3),\(UTFField4)"
        let expected: Array<CSVRecord> = [[Field1, Field2, Field3, UTFField4], [Field1, Field2, Field3, UTFField4]]
        _ = parse(csv, expected)
    }
    
    func testEmptyFields() {
        let csv = COMMA+COMMA
        let expected: Array<CSVRecord> = [[EMPTY, EMPTY, EMPTY]]
        _ = parse(csv, expected)
    }
    
    func testSimpleWithInnerQuote() {
        let csv = FIELD1+COMMA+FIELD2+DOUBLEQUOTE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+DOUBLEQUOTE+FIELD3]]
        _ = parse(csv, expected)
    }
    
    func testSimpleWithDoubledInnerQuote() {
        let csv = FIELD1+COMMA+FIELD2+DOUBLEQUOTE+DOUBLEQUOTE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+DOUBLEQUOTE+DOUBLEQUOTE+FIELD3]]
        _ = parse(csv, expected)
    }
    
    func testInterspersedDoubleQuotes() {
        let csv = FIELD1+COMMA+FIELD2+DOUBLEQUOTE+FIELD3+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+DOUBLEQUOTE+FIELD3+DOUBLEQUOTE]]
        _ = parse(csv, expected)
    }
    
    func testSimpleQuoted() {
        let csv = QUOTED_FIELD1+COMMA+QUOTED_FIELD2+COMMA+QUOTED_FIELD3
        let expected: Array<CSVRecord> = [[QUOTED_FIELD1, QUOTED_FIELD2, QUOTED_FIELD3]]
        _ = parse(csv, expected)
    }
    
    func testSimpleQuotedSanitized() {
        let csv = QUOTED_FIELD1+COMMA+QUOTED_FIELD2+COMMA+QUOTED_FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testSimpleMultiline() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE+FIELD1+COMMA+FIELD2+COMMA+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3], [FIELD1, FIELD2, FIELD3]]
        _ = parse(csv, expected)
    }
    
    func testQuotedDelimiter() {
        let csv = FIELD1+COMMA+DOUBLEQUOTE+FIELD2+COMMA+FIELD3+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[FIELD1, DOUBLEQUOTE+FIELD2+COMMA+FIELD3+DOUBLEQUOTE]]
        _ = parse(csv, expected)
    }
    
    func testSanitizedQuotedDelimiter() {
        let csv = FIELD1+COMMA+DOUBLEQUOTE+FIELD2+COMMA+FIELD3+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+COMMA+FIELD3]]
        var configuration = CSVParser.Configuration()
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testQuotedMultiline() {
        let csv = FIELD1+COMMA+DOUBLEQUOTE+MULTILINE_FIELD+DOUBLEQUOTE+NEWLINE+FIELD2
        let expected: Array<CSVRecord> = [[FIELD1, DOUBLEQUOTE+MULTILINE_FIELD+DOUBLEQUOTE], [FIELD2]]
        _ = parse(csv, expected)
    }
    
    func testSanitizedMultiline() {
        let csv = FIELD1+COMMA+DOUBLEQUOTE+MULTILINE_FIELD+DOUBLEQUOTE+NEWLINE+FIELD2
        let expected: Array<CSVRecord> = [[FIELD1, MULTILINE_FIELD], [FIELD2]]
        var configuration = CSVParser.Configuration()
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testWhitespace() {
        let csv = FIELD1+COMMA+SPACE+SPACE+SPACE+FIELD2+COMMA+FIELD3+SPACE+SPACE+SPACE
        let expected: Array<CSVRecord> = [[FIELD1, SPACE+SPACE+SPACE+FIELD2, FIELD3+SPACE+SPACE+SPACE]]
        _ = parse(csv, expected)
    }
    
    func testTrimmedWhitespace() {
        let csv = FIELD1+COMMA+SPACE+SPACE+SPACE+FIELD2+COMMA+FIELD3+SPACE+SPACE+SPACE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        var configuration = CSVParser.Configuration()
        configuration.trimWhitespace = true
        _ = parse(csv, expected, configuration)
    }
    
    func testSanitizedQuotedWhitespace() {
        let csv = FIELD1+COMMA+DOUBLEQUOTE+SPACE+SPACE+SPACE+FIELD2+DOUBLEQUOTE+COMMA+DOUBLEQUOTE+FIELD3+SPACE+SPACE+SPACE+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[FIELD1, SPACE+SPACE+SPACE+FIELD2, FIELD3+SPACE+SPACE+SPACE]]
        var configuration = CSVParser.Configuration()
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testEscapedFieldWithBackslashes() {
        let csv = DOUBLEQUOTE+FIELD1+BACKSLASH+DOUBLEQUOTE+FIELD2+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[DOUBLEQUOTE+FIELD1+BACKSLASH+DOUBLEQUOTE+FIELD2+DOUBLEQUOTE]]
        var configuration = CSVParser.Configuration()
        configuration.recognizeBackslashAsEscape = true
        _ = parse(csv, expected, configuration)
    }
    
    func testUnclosedField() {
        let csv = DOUBLEQUOTE+FIELD1
        
        XCTAssertThrows(try csv.delimitedComponents())
    }
    
    func testStandardEscapedQuote() {
        let csv = DOUBLEQUOTE+FIELD1+DOUBLEQUOTE+DOUBLEQUOTE+FIELD2+DOUBLEQUOTE
        let expected: Array<CSVRecord> = [[FIELD1+DOUBLEQUOTE+FIELD2]]
        var configuration = CSVParser.Configuration()
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testUnrecognizedComment() {
        let csv = FIELD1+NEWLINE+OCTOTHORPE+FIELD2
        let expected: Array<CSVRecord> = [[FIELD1], [OCTOTHORPE+FIELD2]]
        _ = parse(csv, expected)
    }
    
    func testRecognizedComment() {
        let csv = FIELD1+NEWLINE+OCTOTHORPE+FIELD2
        let expected: Array<CSVRecord> = [[FIELD1]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        _ = parse(csv, expected, configuration)
    }
    
    func testCommentWithEscapes() {
        let csv = FIELD1+NEWLINE+OCTOTHORPE+FIELD2+BACKSLASH+NEWLINE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        configuration.recognizeBackslashAsEscape = true
        _ = parse(csv, expected, configuration)
    }
    
    func testInterspersedComment() {
        let csv = FIELD1+NEWLINE+OCTOTHORPE+FIELD2+NEWLINE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1], [FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        _ = parse(csv, expected, configuration)
    }
    
    func testTrimmedComment() {
        let csv = OCTOTHORPE+SPACE+SPACE+FIELD1+SPACE+SPACE
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        configuration.trimWhitespace = true
        configuration.onReadComment = { comment, _ in
            XCTAssertEqual(comment, OCTOTHORPE+SPACE+SPACE+FIELD1)
            return .continue
        }
        configuration.onReadField = { _ in
            XCTFail("Should not have read a field")
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: configuration)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testSanitizedComment() {
        let csv = OCTOTHORPE+SPACE+SPACE+FIELD1+SPACE+SPACE
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        configuration.sanitizeFields = true
        configuration.onReadComment = { comment, _ in
            XCTAssertEqual(comment, SPACE+SPACE+FIELD1+SPACE+SPACE)
            return .continue
        }
        configuration.onReadField = { _ in
            XCTFail("Should not have read a field")
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: configuration)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testTrimmedAndSanitizedComment() {
        let csv = OCTOTHORPE+SPACE+SPACE+FIELD1+SPACE+SPACE
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeComments = true
        configuration.sanitizeFields = true
        configuration.trimWhitespace = true
        configuration.onReadComment = { comment, _ in
            XCTAssertEqual(comment, FIELD1)
            return .continue
        }
        configuration.onReadField = { _ in
            XCTFail("Should not have read a field")
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: configuration)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testTrailingNewline() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2]]
        _ = parse(csv, expected)
    }
    
    func testTrailingSpace() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+SPACE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2], [SPACE]]
        _ = parse(csv, expected)
    }
    
    func testTrailingTrimmedSpace() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+SPACE
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2], [EMPTY]]
        var configuration = CSVParser.Configuration()
        configuration.trimWhitespace = true
        _ = parse(csv, expected, configuration)
    }
    
    func testEmoji() {
        let csv = "1️⃣,2️⃣,3️⃣,4️⃣,5️⃣"+NEWLINE+"6️⃣,7️⃣,8️⃣,9️⃣,0️⃣"
        let expected: Array<CSVRecord> = [["1️⃣","2️⃣","3️⃣","4️⃣","5️⃣"],["6️⃣","7️⃣","8️⃣","9️⃣","0️⃣"]]
        _ = parse(csv, expected)
    }
    
    // MARK: Testing Backslashes
    
    func testUnrecognizedBackslash() {
        let csv = FIELD1+COMMA+FIELD2+BACKSLASH+COMMA+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+BACKSLASH, FIELD3]]
        _ = parse(csv, expected)
    }
    
    func testBackslashEscapedComma() {
        let csv = FIELD1+COMMA+FIELD2+BACKSLASH+COMMA+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+BACKSLASH+COMMA+FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeBackslashAsEscape = true
        _ = parse(csv, expected, configuration)
    }
    
    func testSantizedBackslashEscapedComma() {
        let csv = FIELD1+COMMA+FIELD2+BACKSLASH+COMMA+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+COMMA+FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeBackslashAsEscape = true
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testBackslashEscapedNewline() {
        let csv = FIELD1+COMMA+FIELD2+BACKSLASH+NEWLINE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+BACKSLASH+NEWLINE+FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeBackslashAsEscape = true
        _ = parse(csv, expected, configuration)
    }
    
    func testSantizedBackslashEscapedNewline() {
        let csv = FIELD1+COMMA+FIELD2+BACKSLASH+NEWLINE+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2+NEWLINE+FIELD3]]
        
        var configuration = CSVParser.Configuration()
        configuration.recognizeBackslashAsEscape = true
        configuration.sanitizeFields = true
        _ = parse(csv, expected, configuration)
    }
    
    func testCommentWithDanglingBackslash() {
        let csv = OCTOTHORPE+FIELD1+BACKSLASH
        
        var config = CSVParser.Configuration()
        config.recognizeComments = true
        config.recognizeBackslashAsEscape = true
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testEscapedFieldWithDanglingBackslash() {
        let csv = DOUBLEQUOTE+FIELD1+BACKSLASH
        
        var config = CSVParser.Configuration()
        config.recognizeBackslashAsEscape = true
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    // MARK: Testing First Line as Keys
    
    func testOrderedDictionary() {
        let record: CSVRecord = [FIELD1: FIELD1, FIELD2: FIELD2, FIELD3: FIELD3]
        let expected = [FIELD1, FIELD2, FIELD3]
        XCTAssertEqual(record.fields.flatMap { $0.key }, expected)
        
        XCTAssertEqual(record[0], FIELD1, "Unexpected field")
        XCTAssertEqual(record[1], FIELD2, "Unexpected field")
        XCTAssertEqual(record[2], FIELD3, "Unexpected field")
        
        XCTAssertEqual(record[FIELD1], FIELD1, "Unexpected field")
        XCTAssertEqual(record[FIELD2], FIELD2, "Unexpected field")
        XCTAssertEqual(record[FIELD3], FIELD3, "Unexpected field")
    }
    
    func testFirstLineAsKeys() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE+FIELD1+COMMA+FIELD2+COMMA+FIELD3
        let expected: Array<CSVRecord> = [
            [FIELD1: FIELD1, FIELD2: FIELD2, FIELD3: FIELD3]
        ]
        
        guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(useFirstLineAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed, expected)
    }
    
    func testFirstLineAsKeys_SingleLine() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE
        let expected: Array<CSVRecord> = []
        
        guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(useFirstLineAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed, expected)
        
        let csv2 = FIELD1+COMMA+FIELD2+COMMA+FIELD3
        guard let parsed2 = XCTAssertNoThrows(try csv2.delimitedComponents(useFirstLineAsKeys: true)) else { return }
        _ = XCTAssertEqualRecordArrays(parsed2, expected)
    }
    
    func testFirstLineAsKeys_MismatchedFieldCount() {
        let csv = FIELD1+COMMA+FIELD2+COMMA+FIELD3+NEWLINE+FIELD1+COMMA+FIELD2+COMMA+FIELD3+COMMA+FIELD1
        
        XCTAssertThrows(try csv.delimitedComponents(useFirstLineAsKeys: true))
    }
    
    // MARK: Testing Valid Delimiters
    
    func testAllowedDelimiter_Octothorpe() {
        let csv = FIELD1+OCTOTHORPE+FIELD2+OCTOTHORPE+FIELD3
        guard let actual = XCTAssertNoThrows(try csv.delimitedComponents(CSVParser.Configuration(delimiter: "#"))) else { return }
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = XCTAssertEqualRecordArrays(actual, expected)
    }
    
    func testDisallowedDelimiter_Octothorpe() {
        let csv = FIELD1+OCTOTHORPE+FIELD2+OCTOTHORPE+FIELD3
        
        var config = CSVParser.Configuration(delimiter: "#")
        config.recognizeComments = true
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testAllowedDelimiter_Backslash() {
        let csv = FIELD1+BACKSLASH+FIELD2+BACKSLASH+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = parse(csv, expected, CSVParser.Configuration(delimiter: "\\"))
    }
    
    func testDisallowedDelimiter_Backslash() {
        let csv = FIELD1+BACKSLASH+FIELD2+BACKSLASH+FIELD3
        
        var config = CSVParser.Configuration(delimiter: "\\")
        config.recognizeBackslashAsEscape = true
        
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    func testAllowedDelimiter_Equal() {
        let csv = FIELD1+EQUAL+FIELD2+EQUAL+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        
        _ = parse(csv, expected, CSVParser.Configuration(delimiter: "="))
    }
    
    func testDisallowedDelimiter_Equal() {
        let csv = FIELD1+EQUAL+FIELD2+EQUAL+FIELD3
        
        var config = CSVParser.Configuration(delimiter: "=")
        config.recognizeLeadingEqualSign = true
        
        XCTAssertThrows(try csv.delimitedComponents(config))
    }
    
    // MARK: Testing Record Terminators
    
    func testCustomRecordTerminators() {
        let csv = FIELD1+COMMA+FIELD2+OCTOTHORPE+FIELD1+COMMA+FIELD2+COMMA+FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2], [FIELD1, FIELD2, FIELD3]]
        
        let config = CSVParser.Configuration(recordTerminators: ["#"])
        _ = parse(csv, expected, config)
    }
    
    // MARK: Testing Leading Equal
    
    func testLeadingEqual() {
        let csv = FIELD1+COMMA+EQUAL+QUOTED_FIELD2+COMMA+EQUAL+QUOTED_FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, EQUAL+QUOTED_FIELD2, EQUAL+QUOTED_FIELD3]]
        
        var config = CSVParser.Configuration()
        config.recognizeLeadingEqualSign = true
        _ = parse(csv, expected, config)
    }
    
    func testSanitizedLeadingEqual() {
        let csv = FIELD1+COMMA+EQUAL+QUOTED_FIELD2+COMMA+EQUAL+QUOTED_FIELD3
        let expected: Array<CSVRecord> = [[FIELD1, FIELD2, FIELD3]]
        
        var config = CSVParser.Configuration()
        config.recognizeLeadingEqualSign = true
        config.sanitizeFields = true
        _ = parse(csv, expected, config)
    }
    
    // MARK: Testing Cancellation
    
    func testDocumentCancellation() {
        let csv = FIELD1+COMMA+FIELD2
        
        var config = CSVParser.Configuration()
        config.onBeginDocument = {
            return .cancel
        }
        config.onBeginLine = { _ in
            XCTFail("Should not begin line")
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testBeginLineCancellation() {
        let csv = FIELD1+COMMA+FIELD2
        
        var config = CSVParser.Configuration()
        config.onBeginLine = { _ in
            return .cancel
        }
        config.onReadField = { _ in
            XCTFail("Should not read field")
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
    func testEndLineCancellation() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSVParser.Configuration()
        var beginLineCount = 0
        
        config.onBeginLine = { _ in
            beginLineCount += 1
            return .continue
        }
        config.onEndLine = { _ in
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
        XCTAssertEqual(beginLineCount, 1)
    }
    
    func testFieldCancellation() {
        let csv = FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSVParser.Configuration()
        var readFieldCount = 0
        
        config.onReadField = { _ in
            readFieldCount += 1
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
        XCTAssertEqual(readFieldCount, 1)
    }
    
    func testCommentCancellation() {
        let csv = OCTOTHORPE+FIELD1+COMMA+FIELD2+NEWLINE+FIELD1+COMMA+FIELD2
        
        var config = CSVParser.Configuration()
        config.recognizeComments = true
        
        config.onReadField = { _ in
            XCTFail("Should not read field")
            return .cancel
        }
        config.onReadComment = { _ in
            return .cancel
        }
        
        let parser = CSVParser(characterSequence: csv.characters, configuration: config)
        _ = XCTAssertNoThrows(try parser.parse())
    }
    
}
