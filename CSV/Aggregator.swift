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
    public func delimitedComponents(_ configuration: Parser.Configuration = Parser.Configuration(), useFirstRecordAsKeys: Bool = false) throws -> Array<Record> {
        let aggregator = Aggregator(useFirstRecordAsKeys: useFirstRecordAsKeys)
        
        var config = configuration
        config.onBeginDocument = aggregator.beginDocument
        config.onEndDocument = aggregator.endDocument
        config.onBeginRecord = aggregator.beginRecord
        config.onEndRecord = aggregator.endRecord
        config.onReadComment = aggregator.readComment
        config.onReadField = aggregator.readField
        
        let parser = Parser(characters: self.characters, configuration: config)
        try parser.parse()
        
        return aggregator.records
    }
}

private class Aggregator {
    let useFirstRecordAsKeys: Bool
    var keys: Array<String>? = nil
    var records = Array<Record>()
    
    var currentRecord: Array<String>? = nil
    
    init(useFirstRecordAsKeys keys: Bool) {
        useFirstRecordAsKeys = keys
    }
    
    func beginDocument() -> Parser.Disposition {
        return .continue
    }
    
    func endDocument(_ progress: Progress, _ error: Parser.Error?) { }
    
    func beginRecord(_ progress: CSV.Progress) -> Parser.Disposition {
        currentRecord = []
        return .continue
    }
    
    func endRecord(_ progress: CSV.Progress) -> Parser.Disposition {
        guard let record = progress.record else {
            fatalError("Got an end-of-record callback, but no record")
        }
        
        if let fields = currentRecord {
            if record == 0 && useFirstRecordAsKeys {
                keys = currentRecord
            } else {
                if useFirstRecordAsKeys {
                    guard keys?.count == fields.count else {
                        let field = max(fields.count - 1, 0)
                        let newProgress = CSV.Progress(byteCount: progress.byteCount, characterCount: progress.characterCount, record: record, field: UInt(field))
                        let error = Parser.Error(kind: .illegalNumberOfFields, progress: newProgress)
                        return .error(error)
                    }
                }
                let record = Record(index: record, array: fields, keys: keys)
                records.append(record)
            }
        }
        currentRecord = nil
        return .continue
    }
    
    func readField(_ field: String, progress: CSV.Progress) -> Parser.Disposition {
        currentRecord?.append(field)
        return .continue
    }
    
    func readComment(_ comment: String, progress: CSV.Progress) -> Parser.Disposition {
        if currentRecord?.isEmpty == true {
            currentRecord = nil
        }
        return .continue
    }
}
