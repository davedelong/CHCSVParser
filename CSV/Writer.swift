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
    
    private let output: OutputStream
    private let encoding: String.Encoding
    private let bom: Data
    private let configuration: Writer.Configuration
    
    private let pendingBuffer = NSMutableData()
    
    private let rawDelimiter: Data
    private let rawRecordTerminator: Data
    
    private var currentRecord = 0
    private var currentField = 0
    private var firstLineKeys = Array<String>()
    
    public init(outputStream: OutputStream, encoding: String.Encoding = .utf8, configuration: Writer.Configuration) throws {
        self.output = outputStream
        self.encoding = encoding
        self.bom = encoding.bom
        self.configuration = configuration
        
        self.rawDelimiter = String(configuration.delimiter).data(using: encoding)!.removing(prefix: self.bom)
        self.rawRecordTerminator = String(configuration.recordTerminator).data(using: encoding)!.removing(prefix: self.bom)
        
        
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
        
        
        self.pendingBuffer.append(self.bom)
    }
    
    deinit {
        close()
    }
    
    private func writeToStreamIfNecessary(flush: Bool = false) {
        repeat {
            // if there's nothing to write, immediately return
            guard pendingBuffer.length > 0 else { return }
            
            // open the stream if it's not already
            if output.streamStatus == .notOpen { output.open() }
            
            // make sure the stream is in a state where it can receive bytes
            guard [.opening, .open, .writing].contains(output.streamStatus) else { return }
            
            // only write if we have 1K or we want to flush
            guard pendingBuffer.length >= 1024 || flush == true else { return }
            
            // make sure there's space in the stream for the bytes
            guard output.hasSpaceAvailable || flush == true else { return }
            
            // write!
            let buffer = pendingBuffer.bytes.bindMemory(to: UInt8.self, capacity: pendingBuffer.length)
            let writtenLength = output.write(buffer, maxLength: pendingBuffer.length)
            pendingBuffer.replaceBytes(in: NSMakeRange(0, writtenLength), withBytes: [])
        } while flush == true
    }
    
    private func write(data: Data) {
        pendingBuffer.append(data)
        writeToStreamIfNecessary()
    }
    
    private func finishRecordIfNecessary() {
        if currentField > 0 {
            write(data: rawRecordTerminator)
        }
        currentField = 0
        currentRecord += 1
    }
    
    private func writeDelimiter() {
        write(data: rawDelimiter)
        currentField += 1
    }
    
    public func write(field: String) {
        if currentRecord == 0 {
            firstLineKeys.append(field)
        }
        if currentField > 0 { writeDelimiter() }
        // TODO: escape the field
        
        let fieldData = field.data(using: encoding)!.removing(prefix: bom)
        write(data: fieldData)
    }
    
    public func write(field: Field) {
        write(field: field.value)
    }
    
    public func finishRecord() {
        write(data: rawRecordTerminator)
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
        
        for key in firstLineKeys {
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
        
        let lines = comment.components(separatedBy: String(configuration.recordTerminator))
        for (index, line) in lines.enumerated() {
            let string = "#" + line
            let fieldData = string.data(using: encoding)!.removing(prefix: bom)
            write(data: fieldData)
            
            if index != lines.count - 1 { write(data: rawRecordTerminator) }
        }
    }
    
    public func close() {
        writeToStreamIfNecessary(flush: true)
        if output.streamStatus != .closed { output.close() }
    }
    
}
