//
//  Scenarios.swift
//  CSV
//
//  Created by Dave DeLong on 4/9/17.
//
//

import Foundation
import CSV
import XCTest

struct Scenario {
    let file: StaticString
    let line: UInt
    let name: String
    let csv: String
    let configuration: CSV.Parser.Configuration
    let document: CSV.Document?
    var reversible: Bool {
        return configuration.trimWhitespace == false
    }
    
    init(name: String, csv: String, configuration: CSV.Parser.Configuration = CSV.Parser.Configuration(), document: CSV.Document?, file: StaticString = #file, line: UInt = #line) {
        self.name = name
        self.csv = csv
        self.configuration = configuration
        self.document = document
        
        self.file = file
        self.line = line
    }
    
    func testParser() {
        if let doc = document {
            // we are expecting the csv to PASS parsing
            _ = parse(csv, doc.records, configuration, file: file, line: line)
        } else {
            // we are expecting the csv to FAIL parsing
            let parser = CSV.Parser(characters: csv.characters, configuration: configuration)
            _ = XCTAssertThrows(try parser.parse(), file: file, line: line)
        }
    }
    
    func testWriter() {
        // test that the document matches the csv
        guard let doc = document else { return }
        guard reversible == true else { return }
        
        var c = CSV.Writer.Configuration(delimiter: configuration.delimiter,
                                         recordTerminator: configuration.recordTerminators.first!)
        if configuration.recognizeComments == true {
            c.allowComments = true
        }
        if configuration.recognizeBackslashAsEscape == true {
            c.useBackslashAsEscape = true
        }
        
        let output = StringTextOutputStream()
        let writer = XCTAssertNoThrows(try CSV.Writer(stream: output, configuration: c), file: file, line: line)
        guard let w = writer else { return }
        for record in doc {
            w.write(record: record)
        }
        
        let writtenCSV = output.output
        
        XCTAssertEqual(writtenCSV, csv, file: file, line: line)
    }
}

let simpleScenarios: Array<Scenario> = [
    Scenario(name: "Simple",
             csv: "a,b,c",
        document: Document([Record([Field("a"), Field("b"), Field("c")])])
    ),
    
    Scenario(name: "SimpleUTF8",
             csv: "a,b,c,ȡ\na,b,c,ƌ",
        document: Document([Record([Field("a"), Field("b"), Field("c"), Field("ȡ")]), Record([Field("a"), Field("b"), Field("c"), Field("ƌ")])])
    ),
    
    Scenario(name: "EmptyDocument",
             csv: "",
             document: Document([Record([Field("")])])
    ),
    
    Scenario(name: "EmptyFields",
             csv: ",,",
             document: Document([Record([Field(""), Field(""), Field("")])])
    ),
    
    Scenario(name: "SimpleWithInnerQuote",
             csv: "a,b\"c",
             document: Document([Record([Field("a"), Field("b\"c")])])
    ),
    
    Scenario(name: "SimpleWithDoubledInnerQuote",
             csv: "a,b\"\"c",
             document: Document([Record([Field("a"), Field("b\"\"c")])])
    ),
    
    Scenario(name: "InterspersedDoubleQuotes",
             csv: "a,b\"c\"",
             document: Document([Record([Field("a"), Field("b\"c\"")])])
    ),
    
    Scenario(name: "SimpleQuoted",
             csv: "\"a\",\"b\",\"c\"",
             document: Document([Record([Field("\"a\""), Field("\"b\""), Field("\"c\"")])])
    ),
    
    Scenario(name: "SimpleQuotedSanitized",
             csv: "\"a\",\"b\",\"c\"",
             configuration: CSV.Parser.Configuration(sanitizeFields: true),
             document: Document([Record([Field("a"), Field("b"), Field("c")])])
    ),
    
    Scenario(name: "SimpleMultiline",
             csv: "a,b,c\na,b,c",
             document: Document([Record([Field("a"), Field("b"), Field("c")]), Record([Field("a"), Field("b"), Field("c")])])
    ),
    
    Scenario(name: "EmptyMultilineDocument",
             csv: "\n",
             document: Document([Record([Field("")]), Record([Field("")])])
    ),
]

let quotedScenarios: Array<Scenario> = [
    
    Scenario(name: "QuotedDelimiter",
             csv: "a,\"b,c\"",
             document: Document([Record([Field("a"), Field("\"b,c\"")])])
    ),
    
    Scenario(name: "SanitizedQuotedDelimiter",
             csv: "a,\"b,c\"",
             configuration: CSV.Parser.Configuration(sanitizeFields: true),
             document: Document([Record([Field("a"), Field("b,c")])])
    ),
    
    Scenario(name: "QuotedMultiline",
             csv: "a,\"a\nb\"\nb",
             document: Document([Record([Field("a"), Field("\"a\nb\"")]), Record([Field("b")])])
    ),
    
    Scenario(name: "SanitizedMultiline",
             csv: "a,\"a\nb\"\nb",
             configuration: CSV.Parser.Configuration(sanitizeFields: true),
             document: Document([Record([Field("a"), Field("a\nb")]), Record([Field("b")])])
    ),
    
    Scenario(name: "Whitespace",
             csv: "a,   b,c   ",
             document: Document([Record([Field("a"), Field("   b"), Field("c   ")])])
    ),
    
    Scenario(name: "TrimmedWhitespace",
             csv: "a,   b,c   ",
             configuration: CSV.Parser.Configuration(trimWhitespace: true),
             document: Document([Record([Field("a"), Field("b"), Field("c")])])
    ),
    
    Scenario(name: "SanitizedQuotedWhitespace",
             csv: "a,\"   b\",\"c   \"",
             configuration: CSV.Parser.Configuration(sanitizeFields: true),
             document: Document([Record([Field("a"), Field("   b"), Field("c   ")])])
    ),
    
    Scenario(name: "EscapedFieldWithBackslashes",
             csv: "\"a\\\"b\"",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true),
             document: Document([Record([Field("\"a\\\"b\"")])])
    ),
    
    Scenario(name: "UnclosedField",
             csv: "\"a",
             document: nil
    ),
    
    Scenario(name: "StandardEscapedQuote",
             csv: "\"a\"\"b\"",
             configuration: CSV.Parser.Configuration(sanitizeFields: true),
             document: Document([Record([Field("a\"b")])])
    )
]

let commentScenarios: Array<Scenario> = [
    
    Scenario(name: "UnrecognizedComment",
             csv: "a\n#b",
             document: Document([Record([Field("a")]), Record([Field("#b")])])
    ),
    
    Scenario(name: "RecognizedComment",
             csv: "a\n#b",
             configuration: CSV.Parser.Configuration(recognizeComments: true),
             document: Document([Record([Field("a")]), Record(comment: "#b")])
    ),
    
    Scenario(name: "CommentWithEscapes",
             csv: "a\n#b\\\nc",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true, recognizeComments: true),
             document: Document([Record([Field("a")]), Record(comment: "#b\\\nc")])
    ),
    
    Scenario(name: "InterspersedComment",
             csv: "a\n#b\nc",
             configuration: CSV.Parser.Configuration(recognizeComments: true),
             document: Document([Record([Field("a")]), Record(comment: "#b"), Record([Field("c")])])
    ),
    
    Scenario(name: "TrimmedComment",
             csv: "#  a  ",
             configuration: CSV.Parser.Configuration(recognizeComments: true, trimWhitespace: true),
             document: Document([Record(comment: "#  a")])
    ),
    
    Scenario(name: "SanitizedComment",
             csv: "#  a  ",
             configuration: CSV.Parser.Configuration(sanitizeFields: true, recognizeComments: true),
             document: Document([Record(comment: "  a  ")])
    ),
    
    Scenario(name: "TrimmedSanitizedComment",
             csv: "#  a  ",
             configuration: CSV.Parser.Configuration(sanitizeFields: true, recognizeComments: true, trimWhitespace: true),
             document: Document([Record(comment: "a")])
    )
]

let trailingWhitespaceScenarios: Array<Scenario> = [
    
    Scenario(name: "TrailingNewline",
             csv: "a,b\n",
             document: Document([Record([Field("a"), Field("b")])])
    ),
    
    Scenario(name: "TrailingSpace",
             csv: "a,b\n ",
             document: Document([Record([Field("a"), Field("b")]), Record([Field(" ")])])
    ),
    
    Scenario(name: "TrailingTrimmedSpace",
             csv: "a,b\n ",
             configuration: CSV.Parser.Configuration(trimWhitespace: true),
             document: Document([Record([Field("a"), Field("b")]), Record([Field("")])])
    )
]

let emojiScenarios: Array<Scenario> = [
    
    Scenario(name: "Emoji",
             csv: "1️⃣,2️⃣,3️⃣,4️⃣,5️⃣\n6️⃣,7️⃣,8️⃣,9️⃣,0️⃣",
             document: Document([Record([Field("1️⃣"),Field("2️⃣"),Field("3️⃣"),Field("4️⃣"),Field("5️⃣")]),Record([Field("6️⃣"),Field("7️⃣"),Field("8️⃣"),Field("9️⃣"),Field("0️⃣")])])
    )
    
]

let backslashScenarios: Array<Scenario> = [
    
    // MARK: Testing Backslashes
    
    Scenario(name: "UnrecognizedBackslash",
             csv: "a,b\\,c",
             document: Document([Record([Field("a"), Field("b\\"), Field("c")])])
    ),
    
    Scenario(name: "BackslashEscapedComma",
             csv: "a,b\\,c",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true),
             document: Document([Record([Field("a"), Field("b\\,c")])])
    ),
    
    Scenario(name: "SantizedBackslashEscapedComma",
             csv: "a,b\\,c",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true, sanitizeFields: true),
             document: Document([Record([Field("a"), Field("b,c")])])
    ),
    
    Scenario(name: "BackslashEscapedNewline",
             csv: "a,b\\\nc",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true),
             document: Document([Record([Field("a"), Field("b\\\nc")])])
    ),
    
    Scenario(name: "SantizedBackslashEscapedNewline",
             csv: "a,b\\\nc",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true, sanitizeFields: true),
             document: Document([Record([Field("a"), Field("b\nc")])])
    ),
    
    Scenario(name: "CommentWithDanglingBackslash",
             csv: "#a\\",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true, recognizeComments: true),
             document: nil
    ),
    
    Scenario(name: "EscapedFieldWithDanglingBackslash",
             csv: "\"a\\",
             configuration: CSV.Parser.Configuration(recognizeBackslashAsEscape: true),
             document: nil
    )
    
]
