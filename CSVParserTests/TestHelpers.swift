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

func parse(csv: String, _ expected: Array<CSVRecord>, configuration: CSVParserConfiguration = CSVParserConfiguration(), file: String = __FILE__, line: UInt = __LINE__) {
    
    if let parsed = try? csv.delimitedComponents(configuration, useFirstLineAsKeys: false) {
        XCTAssertEqual(parsed.count, expected.count, "incorrect number of records", file: file, line: line)
        if parsed.count == expected.count {
            for (p, e) in zip(parsed, expected) {
                XCTAssertEqual(p.fields.count, e.fields.count, "incorrect number of fields on line \(p.index)", file: file, line: line)
                if p.fields.count == e.fields.count {
                    for (pf, ef) in zip(p.fields, e.fields) {
                        XCTAssertEqual(pf.value, ef.value, "mismatched field #\(pf.index) on line \(p.index)", file: file, line: line)
                        if pf.value != ef.value {
                            NSLog("expected data: \(ef.value.dataUsingEncoding(NSUTF8StringEncoding))")
                            NSLog("actual data  : \(pf.value.dataUsingEncoding(NSUTF8StringEncoding))")
                        }
                    }
                }
            }
        }
    }
}
