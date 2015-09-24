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

func XCTAssertEqualSequences<S1: SequenceType, S2: SequenceType where S2.Generator.Element == S1.Generator.Element, S2.Generator.Element: Equatable>(actual: S1, _ expected: S2, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> Bool {
    var itemIndex = 0
    
    var actualGenerator = actual.generate()
    var expectedGenerator = expected.generate()
    
    while let actualNext = actualGenerator.next(), let expectedNext = expectedGenerator.next() {
        guard actualNext == expectedNext else {
            let description = "Expected \(expectedNext) but got \(actualNext) at character index \(itemIndex)"
            let finalMessage = message.isEmpty ? description : "\(message). \(description)"
            XCTFail(finalMessage, file: file, line: line)
            return false
        }
        itemIndex++
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


private var temporaryFolderLogging = Dictionary<String, Bool>()
extension XCTestCase {
    
    internal func resource(name: String, type: String = "csv", file: String = __FILE__, line: UInt = __LINE__) -> NSURL? {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let url = bundle.URLForResource(name, withExtension: type) {
            return url
        }
        XCTFail("Unable to load file \(name).\(type)", file: file, line: line)
        return nil
    }
    
    internal func temporaryFile(name: String, function: String = __FUNCTION__) -> NSURL {
        let tmp: NSString = NSTemporaryDirectory()
        let classFolder: NSString = tmp.stringByAppendingPathComponent("\(self.dynamicType)")
        let functionFolder: NSString = classFolder.stringByAppendingPathComponent(function)
        let file = functionFolder.stringByAppendingPathComponent(name)
        
        do {
            let fm = NSFileManager.defaultManager()
            let folder = functionFolder as String
            var isDir: ObjCBool = false
            if fm.fileExistsAtPath(folder, isDirectory: &isDir) == false || isDir.boolValue == false {
                _ = try fm.createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil)
            }
            
            if temporaryFolderLogging[folder] != true {
                temporaryFolderLogging[folder] = true
                print("\t\(functionFolder)")
            }
        } catch _ { }
        
        
        return NSURL(fileURLWithPath: file)
    }
}
