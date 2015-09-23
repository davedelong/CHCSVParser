//
//  TestHelpers.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
import CSVParser

let Field1 = "Field1"
let Field2 = "Field2"
let Field3 = "Field3"
let UTFField4 = "ḟīễłđ➃"

let EMPTY = ""
let COMMA = ","
let SEMICOLON = ";"
let DOUBLEQUOTE = "\""
let NEWLINE = "\n"
let TAB = "\t"
let SPACE = " "
let BACKSLASH = "\\"
let OCTOTHORPE = "#"
let EQUAL = "="

let FIELD1 = "field1"
let FIELD2 = "field2"
let FIELD3 = "field3"
let UTF8FIELD4 = "ḟīễłđ➃"

let QUOTED_FIELD1 = DOUBLEQUOTE + FIELD1 + DOUBLEQUOTE
let QUOTED_FIELD2 = DOUBLEQUOTE + FIELD2 + DOUBLEQUOTE
let QUOTED_FIELD3 = DOUBLEQUOTE + FIELD3 + DOUBLEQUOTE

let MULTILINE_FIELD = FIELD1 + NEWLINE + FIELD2

func parse(csv: String, _ expected: Array<CSVRecord>, _ configuration: CSVParserConfiguration = CSVParserConfiguration(), file: String = __FILE__, line: UInt = __LINE__) {
    guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(configuration, useFirstLineAsKeys: false), file: file, line: line) else { return }
    XCTAssertEqualRecordArrays(parsed, expected, file: file, line: line)
}

func XCTAssertEqualRecordArrays(actual: Array<CSVRecord>, _ expected: Array<CSVRecord>, file: String = __FILE__, line: UInt = __LINE__) -> Bool {
    XCTAssertEqual(actual.count, expected.count, "incorrect number of records", file: file, line: line)
    guard actual.count == expected.count else { return false }
    
    for (a, e) in zip(actual, expected) {
        XCTAssertEqual(a.fields.count, e.fields.count, "incorrect number of fields on line \(a.index)", file: file, line: line)
        guard a.fields.count == e.fields.count else { return false }
        for (pf, ef) in zip(a.fields, e.fields) {
            XCTAssertEqual(pf.value, ef.value, "mismatched field #\(pf.index) on line \(a.index)", file: file, line: line)
            guard pf.value == ef.value else { return false }
        }
    }
    
    return true
}

func XCTAssertNoThrows(@autoclosure expression: () throws -> Void, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> Bool {
    var ok = false
    do {
        try expression()
        ok = true
    } catch let e {
        let failMessage = "Unexpected exception: \(e). \(message)"
        XCTFail(failMessage, file: file, line: line)
    }
    return ok
}

func XCTAssertNoThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> T? {
    var t: T? = nil
    do {
        t = try expression()
    } catch let e {
        let failMessage = "Unexpected exception: \(e). \(message)"
        XCTFail(failMessage, file: file, line: line)
    }
    return t
}

func XCTAssertThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let _ = try expression()
        XCTFail("Expected thrown error", file: file, line: line)
    } catch _ {
    }
}

extension XCTestCase {
    
    internal func resource(name: String, type: String = "csv", file: String = __FILE__, line: UInt = __LINE__) -> NSURL? {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let url = bundle.URLForResource(name, withExtension: type) {
            return url
        }
        XCTFail("Unable to load file \(name).\(type)", file: file, line: line)
        return nil
    }
    
}
