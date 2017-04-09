//
//  OutputStreams.swift
//  CSV
//
//  Created by Dave DeLong on 4/9/17.
//
//

import Foundation

public final class StringTextOutputStream: TextOutputStream {
    public private(set) var output = ""
    public init() { }
    
    public func write(_ string: String) { output.append(string) }
}

public final class CompositeTextOutputStream: TextOutputStream, ExpressibleByArrayLiteral {
    
    // a helper class to cover up the fact that TextOutputStream requires a mutating func
    private class MutatingWrapper: TextOutputStream {
        private var stream: TextOutputStream
        
        init(_ stream: TextOutputStream) { self.stream = stream }
        func write(_ string: String) { stream.write(string) }
    }
    
    private var streams: Array<MutatingWrapper>
    
    public init(_ s: Array<TextOutputStream>) { self.streams = s.map { MutatingWrapper($0) } }
    public convenience init(streams: TextOutputStream ...) { self.init(streams) }
    public convenience init(arrayLiteral: TextOutputStream ...) { self.init(arrayLiteral) }
    
    public func write(_ string: String) { streams.forEach { $0.write(string) } }
    
}

public final class OutputStreamWrapper: TextOutputStream {
    private let output: OutputStream
    private let encoding: String.Encoding
    private let bom: Data
    private let pendingBuffer = NSMutableData()
    
    public convenience init(toFile file: URL, encoding: String.Encoding) throws {
        guard file.isFileURL else {
            throw Writer.Error(kind: .invalidOutputStream)
        }
        guard let outputStream = OutputStream(url: file, append: false) else {
            throw Writer.Error(kind: .invalidOutputStream)
        }
        self.init(outputStream: outputStream, encoding: encoding)
    }
    
    public init(outputStream: OutputStream, encoding: String.Encoding) {
        
        self.output = outputStream
        self.encoding = encoding
        self.bom = encoding.bom
        
        self.pendingBuffer.append(self.bom)
    }
    
    deinit {
        writeToStreamIfNecessary(flush: true)
        if output.streamStatus != .closed { output.close() }
    }
    
    public func write(_ string: String) {
        guard let data = string.data(using: encoding) else {
            fatalError("Unable to convert string into encoding: \(encoding.name ?? encoding.description)")
        }
        let dataWithoutBOM = data.removing(prefix: bom)
        pendingBuffer.append(dataWithoutBOM)
        writeToStreamIfNecessary()
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
    
}
