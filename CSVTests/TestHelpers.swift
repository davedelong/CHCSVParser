//
//  TestHelpers.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
import CSV

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

func parse(_ csv: String, _ expected: Array<Record>, _ configuration: CSV.Parser.Configuration = CSV.Parser.Configuration(), file: StaticString = #file, line: UInt = #line) -> Bool {
    guard let parsed = XCTAssertNoThrows(try csv.delimitedComponents(configuration, useFirstRecordAsKeys: false), file: file, line: line) else { return false }
    return XCTAssertEqualRecordArrays(parsed.records, expected, file: file, line: line)
}

func XCTAssertEqualRecordArrays(_ actual: Array<Record>, _ expected: Array<Record>, file: StaticString = #file, line: UInt = #line) -> Bool {
    XCTAssertEqual(actual.count, expected.count, "incorrect number of records", file: file, line: line)
    guard actual.count == expected.count else { return false }
    
    for (a, e) in zip(actual, expected) {
        switch (a, e) {
            case (.comment(let l), .fields(let r)):
                XCTFail("Expected \(r.count) fields, but got comment \"\(l)\"", file: file, line: line); return false
            
            case (.fields(let l), .comment(let r)):
                XCTFail("Expected comment \"\(r)\", but for \(l.count) fields", file: file, line: line); return false
            
            case (.comment(let l), .comment(let r)):
                XCTAssertEqual(l, r, file: file, line: line);
                guard l == r else { return false }
            
            case (.fields(let l), .fields(let r)):
                guard l.count == r.count else {
                    XCTFail("expected \(r.count) fields but got \(l.count)", file: file, line: line)
                    return false
                }
                for (lField, rField) in zip(l, r) {
                    XCTAssertEqual(lField.value, rField.value, file: file, line: line)
                    guard lField.value == rField.value else { return false }
                }
        }
    }
    
    return true
}

func XCTAssertEqualSequences<S1: Sequence, S2: Sequence>(_ actual: S1, _ expected: S2, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> Bool where S2.Iterator.Element == S1.Iterator.Element, S2.Iterator.Element: Equatable {

    let actualIterator = actual.makeIterator()
    let expectedIterator = expected.makeIterator()
    
    return XCTAssertEqualIterators(actualIterator, expectedIterator, message, file: file, line: line)
}

func XCTAssertEqualIterators<G1: IteratorProtocol, G2: IteratorProtocol>(_ actual: G1, _ expected: G2, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> Bool where G2.Element == G1.Element, G2.Element: Equatable {
    var actual = actual, expected = expected
    var itemIndex = 0
    
    while let actualNext = actual.next(), let expectedNext = expected.next() {
        guard actualNext == expectedNext else {
            let description = "Expected \(expectedNext) but got \(actualNext) at character index \(itemIndex)"
            let finalMessage = message.isEmpty ? description : "\(message). \(description)"
            XCTFail(finalMessage, file: file, line: line)
            return false
        }
        itemIndex += 1
    }
    
    return true
}

func XCTAssertNoThrows(_ expression: @autoclosure () throws -> Void, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> Bool {
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

func XCTAssertNoThrows<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> T? {
    var t: T? = nil
    do {
        t = try expression()
    } catch let e {
        let failMessage = "Unexpected exception: \(e). \(message)"
        XCTFail(failMessage, file: file, line: line)
    }
    return t
}

func XCTAssertThrows<T>(_ expression: @autoclosure () throws -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) -> Bool {
    do {
        let _ = try expression()
        XCTFail("Expected thrown error", file: file, line: line)
        return false
    } catch _ {
        return true
    }
}


private var temporaryFolderLogging = Dictionary<String, Bool>()
extension XCTestCase {
    
    internal func resource(_ name: String, type: String = "csv", file: StaticString = #file, line: UInt = #line) -> URL? {
        let bundle = Bundle(for: type(of: self))
        if let url = bundle.url(forResource: name, withExtension: type) {
            return url
        }
        XCTFail("Unable to load file \(name).\(type)", file: file, line: line)
        return nil
    }
    
    internal func temporaryFile(_ name: String, function: String = #function) -> URL {
        let tmp: NSString = NSTemporaryDirectory() as NSString
        let classFolder: NSString = tmp.appendingPathComponent("\(type(of: self))") as NSString
        let functionFolder: NSString = classFolder.appendingPathComponent(function) as NSString
        let file = functionFolder.appendingPathComponent(name)
        
        do {
            let fm = FileManager.default
            let folder = functionFolder as String
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: folder, isDirectory: &isDir) == false || isDir.boolValue == false {
                _ = try fm.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
            }
            
            if temporaryFolderLogging[folder] != true {
                temporaryFolderLogging[folder] = true
                print("\t\(functionFolder)")
            }
        } catch _ { }
        
        
        return URL(fileURLWithPath: file)
    }
}
