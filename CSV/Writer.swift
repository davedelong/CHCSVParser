//
//  CSVWriter.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/27/15.
//
//

import Foundation

public final class Writer {
    
    public struct Configuration {
        public var delimiter: Character
        public var recordTerminator: Character
        
        public var useBackslashAsEscape = false
        public var allowComments = false
        
        public init(delimiter: Character = ",", recordTerminator: Character = "\n") {
            self.delimiter = delimiter
            self.recordTerminator = recordTerminator
        }
    }
    
    private var outputStream: TextOutputStream
    private let configuration: Writer.Configuration
    
    private let delimiter: String
    private let recordTerminator: String
    
    private var currentRecord: UInt = 0
    private var currentField: UInt = 0
    private var firstRecordKeys = Array<String>()
    private var canWrite = true
    
    public init(stream: TextOutputStream, configuration: Writer.Configuration) throws {
        guard configuration.delimiter != configuration.recordTerminator else {
            throw Writer.Error(kind: .illegalRecordTerminator)
        }
        guard configuration.allowComments == false || configuration.delimiter != Character.Octothorpe else {
            throw Writer.Error(kind: .illegalDelimiter)
        }
        guard configuration.allowComments == false || configuration.recordTerminator != Character.Octothorpe else {
            throw Writer.Error(kind: .illegalRecordTerminator)
        }
        guard configuration.useBackslashAsEscape == false || configuration.delimiter != Character.Backslash else {
            throw Writer.Error(kind: .illegalDelimiter)
        }
        guard configuration.useBackslashAsEscape == false || configuration.recordTerminator != Character.Backslash else {
            throw Writer.Error(kind: .illegalRecordTerminator)
        }
        
        self.outputStream = stream
        self.configuration = configuration
        
        self.delimiter = String(configuration.delimiter)
        self.recordTerminator = String(configuration.recordTerminator)
    }
    
    public convenience init(outputStream: OutputStream, encoding: String.Encoding = .utf8, configuration: Writer.Configuration) throws {
        let streamWrapper = OutputStreamWrapper(outputStream: outputStream, encoding: encoding)
        try self.init(stream: streamWrapper, configuration: configuration)
    }
    
    deinit {
        close()
    }
    
    private func write(rawString: String) {
        guard canWrite == true else {
            fatalError("Cannot write to a stream that is closed")
        }
        outputStream.write(rawString)
    }
    
    private func finishRecordIfNecessary() {
        if currentField > 0 {
            write(rawString: recordTerminator)
        }
        currentField = 0
        currentRecord += 1
    }
    
    private func writeDelimiter() {
        write(rawString: delimiter)
        currentField += 1
    }
    
    public func write(field: String) {
        if currentRecord == 0 {
            firstRecordKeys.append(field)
        }
        if currentField > 0 { writeDelimiter() }
        // TODO: escape the field
        
        write(rawString: field)
    }
    
    public func write(field: Field) {
        write(field: field.value)
    }
    
    public func finishRecord() {
        write(rawString: recordTerminator)
        currentField = 0
        currentRecord += 1
    }
    
    public func write(record fields: String ...) {
        finishRecordIfNecessary()
        for field in fields {
            write(field: field)
        }
        finishRecord()
    }
    
    public func write(record: Record) {
        finishRecordIfNecessary()
        for field in record.fields {
            write(field: field.value)
        }
        finishRecord()
    }
    
    public func write(fields: Dictionary<String, String>) throws {
        if currentRecord == 0 {
            throw Writer.Error(kind: .invalidRecord)
        }
        
        finishRecordIfNecessary()
        
        for key in firstRecordKeys {
            guard let field = fields[key] else {
                throw Writer.Error(kind: .missingField(key))
            }
            write(field: field)
        }
        
        finishRecord()
    }
    
    public func write(comment: String) {
        guard configuration.allowComments == true else { return }
        
        finishRecordIfNecessary()
        
        // TODO: escape any record terminators in the comments
        let rawComment = "#" + comment
        write(rawString: rawComment)
    }
    
    public func close() {
        canWrite = false
    }
    
}
