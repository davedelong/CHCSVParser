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

public struct CSVRecord: SequenceType, ArrayLiteralConvertible {
    public let index: UInt
    public let fields: Array<CSVField>
    
    public init(arrayLiteral elements: String...) {
        index = 0
        fields = Array(elements.enumerate()).map { (index, element) in
            CSVField(index: UInt(index), key: nil, value: element)
        }
    }
    
    public init(index i: UInt, array: Array<String>, keys: Array<String>? = nil) {
        index = i
        if let keys = keys {
            let keyValue = zip(keys, array)
            fields = Array(keyValue.enumerate()).map { (index, element) in
                CSVField(index: UInt(index), key: element.0, value: element.1)
            }
        } else {
            fields = Array(array.enumerate()).map { (index, element) in
                CSVField(index: UInt(index), key: nil, value: element)
            }
        }
    }
    
    public subscript (index: Int) -> String? {
        if index < fields.count { return fields[index].value }
        return nil
    }
    
    public subscript (index: String) -> String? {
        let match = fields.filter { $0.key == index }
        return match.first?.value
    }
    
    public func generate() -> AnyGenerator<CSVField> {
        return AnySequence(fields).generate()
    }
}

extension String {
    public func delimitedComponents(configuration: CSVParserConfiguration = CSVParserConfiguration(), useFirstLineAsKeys: Bool = false) throws -> Array<CSVRecord> {
        var config = configuration
        let aggregator = CSVAggregator(useFirstLineAsKeys: useFirstLineAsKeys)
        
        config.onBeginDocument = aggregator.beginDocument
        config.onEndDocument = aggregator.endDocument
        config.onBeginLine = aggregator.beginLine
        config.onEndLine = aggregator.endLine
        config.onReadComment = aggregator.readComment
        config.onReadField = aggregator.readField
        
        let parser = CSVParser(characterSequence: self.characters, configuration: config)
        do {
            try parser.parse()
            return aggregator.lines
        } catch let e {
            throw e
        }
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
    
    func beginDocument() { }
    
    func endDocument() { }
    
    func beginLine(line: UInt) {
        currentLine = []
    }
    
    func endLine(line: UInt) {
        if let fields = currentLine {
            if line == 0 && useFirstLineAsKeys {
                keys = currentLine
            } else {
                let record = CSVRecord(index: line, array: fields, keys: keys)
                lines.append(record)
            }
        }
        currentLine = nil
    }
    
    func readField(field: String, index: UInt) {
        currentLine?.append(field)
    }
    
    func readComment(comment: String) { }
}
