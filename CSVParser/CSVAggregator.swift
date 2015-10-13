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

public struct CSVRecord: SequenceType, ArrayLiteralConvertible, DictionaryLiteralConvertible {
    public let index: UInt
    public let fields: Array<CSVField>
    
    public init(arrayLiteral elements: String...) {
        index = 0
        fields = Array(elements.enumerate()).map { (index, element) in
            CSVField(index: UInt(index), key: nil, value: element)
        }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        index = 0
        fields = Array(elements.enumerate()).map { (index, element) in
            CSVField(index: UInt(index), key: element.0, value: element.1)
        }
    }
    
    private init(index i: UInt, array: Array<String>, keys: Array<String>? = nil) {
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
        if index < 0 || index >= fields.count { return nil }
        return fields[index].value
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
    
    func beginDocument() -> ParsingDisposition {
        return .Continue
    }
    
    func endDocument(progress: CSVProgress) { }
    
    func beginLine(line: UInt, progress: CSVProgress) -> ParsingDisposition {
        currentLine = []
        return .Continue
    }
    
    func endLine(line: UInt, progress: CSVProgress) throws -> ParsingDisposition {
        if let fields = currentLine {
            if line == 0 && useFirstLineAsKeys {
                keys = currentLine
            } else {
                if useFirstLineAsKeys {
                    guard keys?.count == fields.count else {
                        let field = max(fields.count - 1, 0)
                        throw CSVParserError(kind: .IllegalNumberOfFields, line: line, field: UInt(field), progress: progress)
                    }
                }
                let record = CSVRecord(index: line, array: fields, keys: keys)
                lines.append(record)
            }
        }
        currentLine = nil
        return .Continue
    }
    
    func readField(field: String, index: UInt, progress: CSVProgress) -> ParsingDisposition {
        currentLine?.append(field)
        return .Continue
    }
    
    func readComment(comment: String, progress: CSVProgress) -> ParsingDisposition {
        if currentLine?.isEmpty == true {
            currentLine = nil
        }
        return .Continue
    }
}
