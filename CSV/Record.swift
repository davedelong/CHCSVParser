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
    
    public init(_ records: Array<Record>) {
        self.records = records
    }
    public init(arrayLiteral elements: Record...) {
        self.init(elements)
    }
    
    public subscript (index: Int) -> Record? {
        if index < 0 || index >= records.count { return nil }
        return records[index]
    }
    
    public func makeIterator() -> AnyIterator<Record> {
        return AnyIterator(records.makeIterator())
    }
}

public enum Record: Sequence, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    case comment(String)
    case fields(Array<Field>)
    
    public var comment: String? {
        guard case .comment(let c) = self else { return nil }
        return c
    }
    
    public var fields: Array<Field>? {
        guard case .fields(let f) = self else { return nil }
        return f
    }
    
    public init(arrayLiteral elements: String...) {
        self = .fields(elements.map { Field($0) })
    }
    
    public init(dictionaryLiteral elements: (String, String)...) {
        self = .fields(elements.map { Field(key: $0.0, value: $0.1) })
    }
    
    public init(_ fields: Array<Field>) {
        self = .fields(fields)
    }
    
    public init(comment: String) {
        self = .comment(comment)
    }
    
    internal init(array: Array<String>, keys: Array<String>? = nil) {
        if let keys = keys {
            let keyValue = zip(keys, array)
            self = .fields(keyValue.map { Field(key: $0.0, value: $0.1) })
        } else {
            self = .fields(array.map { Field($0) })
        }
    }
    
    public subscript (index: Int) -> Field? {
        guard let fields = self.fields else { return nil }
        if index < 0 || index >= fields.count { return nil }
        return fields[index]
    }
    
    public subscript (index: String) -> Field? {
        guard let fields = self.fields else { return nil }
        let match = fields.filter { $0.key == index }
        return match.first
    }
    
    public func makeIterator() -> AnyIterator<Field> {
        guard let fields = self.fields else { return AnyIterator([].makeIterator()) }
        return AnyIterator(fields.makeIterator())
    }
}

public struct Field {
    public let key: String?
    public let value: String
    
    public init(key: String?, value: String) {
        self.key = key
        self.value = value
    }
    
    public init(_ value: String) {
        self.key = nil
        self.value = value
    }
}
