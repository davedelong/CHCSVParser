//
//  CSVAggregator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public struct CSVField {
    public let index: UInt
    public let key: String?
    public let value: String
}

public struct CSVRecord: Sequence, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public let index: UInt
    public let fields: Array<CSVField>
    
    public init(arrayLiteral elements: String...) {
        index = 0
        fields = Array(elements.enumerated()).map { (index, element) in
            CSVField(index: UInt(index), key: nil, value: element)
        }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        index = 0
        fields = Array(elements.enumerated()).map { (index, element) in
            CSVField(index: UInt(index), key: element.0, value: element.1)
        }
    }
    
    fileprivate init(index i: UInt, array: Array<String>, keys: Array<String>? = nil) {
        index = i
        if let keys = keys {
            let keyValue = zip(keys, array)
            fields = Array(keyValue.enumerated()).map { (index, element) in
                CSVField(index: UInt(index), key: element.0, value: element.1)
            }
        } else {
            fields = Array(array.enumerated()).map { (index, element) in
                CSVField(index: UInt(index), key: nil, value: element)
            }
        }
    }
    
    public subscript (index: Int) -> String? {
        if index < 0 || index >= fields.count { return nil }
        return fields[index].value
    }
    
    public subscript (index: String) -> String? {
        let match = fields.filter { $0.key == index }
        return match.first?.value
    }
    
    public func makeIterator() -> AnyIterator<CSVField> {
        return AnySequence(fields).makeIterator()
    }
}

extension String {
    public func delimitedComponents(_ configuration: CSVParser.Configuration = CSVParser.Configuration(), useFirstLineAsKeys: Bool = false) throws -> Array<CSVRecord> {
        let aggregator = CSVAggregator(useFirstLineAsKeys: useFirstLineAsKeys)
        
        var config = configuration
        config.onBeginDocument = aggregator.beginDocument
        config.onEndDocument = aggregator.endDocument
        config.onBeginLine = aggregator.beginLine
        config.onEndLine = aggregator.endLine
        config.onReadComment = aggregator.readComment
        config.onReadField = aggregator.readField
        
        let parser = CSVParser(characterSequence: self.characters, configuration: config)
        try parser.parse()
        
        return aggregator.lines
    }
}

private class CSVAggregator {
    let useFirstLineAsKeys: Bool
    var keys: Array<String>? = nil
    var lines = Array<CSVRecord>()
    
    var currentLine: Array<String>? = nil
    
    init(useFirstLineAsKeys keys: Bool) {
        useFirstLineAsKeys = keys
    }
    
    func beginDocument() -> CSVParsingDisposition {
        return .continue
    }
    
    func endDocument(_ progress: CSVProgress, _ error: CSVParserError?) { }
    
    func beginLine(_ line: UInt, progress: CSVProgress) -> CSVParsingDisposition {
        currentLine = []
        return .continue
    }
    
    func endLine(_ line: UInt, _ progress: CSVProgress) -> CSVParsingDisposition {
        if let fields = currentLine {
            if line == 0 && useFirstLineAsKeys {
                keys = currentLine
            } else {
                if useFirstLineAsKeys {
                    guard keys?.count == fields.count else {
                        let field = max(fields.count - 1, 0)
                        let error = CSVParserError(kind: .illegalNumberOfFields, line: line, field: UInt(field), progress: progress)
                        return .error(error)
                    }
                }
                let record = CSVRecord(index: line, array: fields, keys: keys)
                lines.append(record)
            }
        }
        currentLine = nil
        return .continue
    }
    
    func readField(_ field: String, _ line: UInt, _ fieldIndex: UInt, progress: CSVProgress) -> CSVParsingDisposition {
        currentLine?.append(field)
        return .continue
    }
    
    func readComment(_ comment: String, progress: CSVProgress) -> CSVParsingDisposition {
        if currentLine?.isEmpty == true {
            currentLine = nil
        }
        return .continue
    }
}
