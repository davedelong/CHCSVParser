//
//  CSVAggregator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

extension String {
    public func delimitedComponents(_ configuration: Parser.Configuration = Parser.Configuration(), useFirstRecordAsKeys: Bool = false) throws -> Document {
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
        
        return Document(aggregator.records)
    }
}

private class Aggregator {
    let useFirstRecordAsKeys: Bool
    var keys: Array<String>? = nil
    
    var records = Array<Record>()
    var currentRecord: Array<Field>? = nil
    
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
            if keys == nil && useFirstRecordAsKeys {
                // TODO: what if the currentRecord is all comments
                keys = currentRecord?.flatMap { $0.value }
            } else {
                if useFirstRecordAsKeys {
                    guard keys?.count == fields.count else {
                        let field = max(fields.count - 1, 0)
                        let newProgress = CSV.Progress(byteCount: progress.byteCount, characterCount: progress.characterCount, record: record, field: UInt(field))
                        let error = Parser.Error(kind: .illegalNumberOfFields, progress: newProgress)
                        return .error(error)
                    }
                }
                
                let record = Record(fields)
                records.append(record)
            }
        }
        currentRecord = nil
        return .continue
    }
    
    func readField(_ field: String, progress: CSV.Progress) -> Parser.Disposition {
        var key: String? = nil
        if useFirstRecordAsKeys == true {
            key = keys?[currentRecord?.count ?? 0]
        }
        currentRecord?.append(Field(key: key, value: field))
        return .continue
    }
    
    func readComment(_ comment: String, progress: CSV.Progress) -> Parser.Disposition {
        if currentRecord?.isEmpty == true {
            currentRecord = nil
        }
        return .continue
    }
}
