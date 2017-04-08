//
//  CSVAggregator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

public struct Field {
    public let index: UInt
    public let key: String?
    public let value: String
}

public struct Record: Sequence, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    public let index: UInt
    public let fields: Array<Field>
    
    public init(arrayLiteral elements: String...) {
        index = 0
        fields = Array(elements.enumerated()).map { (index, element) in
            Field(index: UInt(index), key: nil, value: element)
        }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        index = 0
        fields = Array(elements.enumerated()).map { (index, element) in
            Field(index: UInt(index), key: element.0, value: element.1)
        }
    }
    
    fileprivate init(index i: UInt, array: Array<String>, keys: Array<String>? = nil) {
        index = i
        if let keys = keys {
            let keyValue = zip(keys, array)
            fields = Array(keyValue.enumerated()).map { (index, element) in
                Field(index: UInt(index), key: element.0, value: element.1)
            }
        } else {
            fields = Array(array.enumerated()).map { (index, element) in
                Field(index: UInt(index), key: nil, value: element)
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
    
    public func makeIterator() -> AnyIterator<Field> {
        return AnyIterator(fields.makeIterator())
    }
}

extension String {
    public func delimitedComponents(_ configuration: Parser.Configuration = Parser.Configuration(), useFirstLineAsKeys: Bool = false) throws -> Array<Record> {
        let aggregator = Aggregator(useFirstLineAsKeys: useFirstLineAsKeys)
        
        var config = configuration
        config.onBeginDocument = aggregator.beginDocument
        config.onEndDocument = aggregator.endDocument
        config.onBeginLine = aggregator.beginLine
        config.onEndLine = aggregator.endLine
        config.onReadComment = aggregator.readComment
        config.onReadField = aggregator.readField
        
        let parser = Parser(characters: self.characters, configuration: config)
        try parser.parse()
        
        return aggregator.lines
    }
}

private class Aggregator {
    let useFirstLineAsKeys: Bool
    var keys: Array<String>? = nil
    var lines = Array<Record>()
    
    var currentLine: Array<String>? = nil
    
    init(useFirstLineAsKeys keys: Bool) {
        useFirstLineAsKeys = keys
    }
    
    func beginDocument() -> Parser.Disposition {
        return .continue
    }
    
    func endDocument(_ progress: Progress, _ error: Parser.Error?) { }
    
    func beginLine(_ line: UInt, progress: CSV.Progress) -> Parser.Disposition {
        currentLine = []
        return .continue
    }
    
    func endLine(_ line: UInt, _ progress: CSV.Progress) -> Parser.Disposition {
        if let fields = currentLine {
            if line == 0 && useFirstLineAsKeys {
                keys = currentLine
            } else {
                if useFirstLineAsKeys {
                    guard keys?.count == fields.count else {
                        let field = max(fields.count - 1, 0)
                        let error = Parser.Error(kind: .illegalNumberOfFields, line: line, field: UInt(field), progress: progress)
                        return .error(error)
                    }
                }
                let record = Record(index: line, array: fields, keys: keys)
                lines.append(record)
            }
        }
        currentLine = nil
        return .continue
    }
    
    func readField(_ field: String, _ line: UInt, _ fieldIndex: UInt, progress: CSV.Progress) -> Parser.Disposition {
        currentLine?.append(field)
        return .continue
    }
    
    func readComment(_ comment: String, progress: CSV.Progress) -> Parser.Disposition {
        if currentLine?.isEmpty == true {
            currentLine = nil
        }
        return .continue
    }
}
