//
//  Record.swift
//  CSV
//
//  Created by Dave DeLong on 4/9/17.
//
//

import Foundation

public struct Document: Sequence, ExpressibleByArrayLiteral {
    public let records: Array<Record>
    
    public init(records: Array<Record>) {
        self.records = records.enumerated().map { (i, r) -> Record in
            return Record(index: UInt(i), fields: r.fields)
        }
    }
    public init(arrayLiteral elements: Record...) {
        self.init(records: elements)
    }
    
    public subscript (index: Int) -> Record? {
        if index < 0 || index >= records.count { return nil }
        return records[index]
    }
    
    public func makeIterator() -> AnyIterator<Record> {
        return AnyIterator(records.makeIterator())
    }
}

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
    
    internal init(index i: UInt, fields: Array<Field>) {
        index = i
        self.fields = fields
    }
    
    internal init(index i: UInt, array: Array<String>, keys: Array<String>? = nil) {
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
    
    public subscript (index: Int) -> Field? {
        if index < 0 || index >= fields.count { return nil }
        return fields[index]
    }
    
    public subscript (index: String) -> Field? {
        let match = fields.filter { $0.key == index }
        return match.first
    }
    
    public func makeIterator() -> AnyIterator<Field> {
        return AnyIterator(fields.makeIterator())
    }
}
