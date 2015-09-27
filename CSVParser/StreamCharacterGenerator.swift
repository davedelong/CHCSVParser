//
//  StreamCharacterGenerator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

private let DefaultPageSize = 4096
private let DefaultLoadMoreThreshold = 1024

public protocol ByteReporting {
    var bytesRead: UInt { get }
}

public class StreamCharacterGenerator: GeneratorType, ByteReporting {
    public typealias Element = Character
    
    private let input: NSInputStream
    private let bom: NSData
    private let encoding: NSStringEncoding
    
    private let pageSize: Int
    private let loadMoreThreshold: Int
    private var pendingByteBuffer = NSMutableData()
    private var characters = Array<Character>()
    
    public private(set) var bytesRead: UInt
    
    public init(inputStream: NSInputStream, encoding: NSStringEncoding = NSMacOSRomanStringEncoding, pageSize: Int = 4096, loadThreshold: Int = 1024) {
        self.bytesRead = 0
        self.input = inputStream
        self.bom = encoding.bom
        self.encoding = encoding
        
        // page and threshold must be greater than zero
        let page = pageSize > 0 ? pageSize : DefaultPageSize
        let threshold = loadThreshold > 0 ? loadThreshold : DefaultLoadMoreThreshold
        
        // guarantee that pageSize >= loadMoreThreshold
        self.pageSize = max(page, threshold)
        self.loadMoreThreshold = min(page, threshold)
        
        // reserve capacity in the characters array to prevent resizing the array later
        self.characters.reserveCapacity(self.pageSize + self.loadMoreThreshold)
    }
    
    deinit {
        if input.streamStatus != .Closed { input.close() }
    }
    
    public func next() -> Element? {
        readMoreIfNecessary()
        if characters.isEmpty { return nil }
        return characters.removeFirst()
    }
    
    private func readMoreIfNecessary() {
        // we only want to try to load more if we have fewer than 1024 characters
        guard characters.count < loadMoreThreshold else { return }
        
        // open the stream
        if input.streamStatus == .NotOpen { input.open() }
        
        // make sure the stream is open for reading
        guard [.Opening, .Open, .Reading].contains(input.streamStatus) else { return }
        
        // we can only read from the stream if it has something to be read
        guard input.hasBytesAvailable else { return }
        
        var buffer = Array<UInt8>(count: pageSize, repeatedValue: 0)
        let bytesRead = input.read(&buffer, maxLength: pageSize)
        
        self.bytesRead += UInt(bytesRead)
        pendingByteBuffer.appendBytes(buffer, length: bytesRead)
        
        guard pendingByteBuffer.length > 0 else { return }
        
        // this encoding may require a BOM in order to parse correctly
        // insert the bom into the byte buffer
        pendingByteBuffer.insertPrefix(bom)
        
        // try to convert as much of the pendingByteBuffer as possible into a String
        var length = pendingByteBuffer.length
        while length > bom.length {
            if let string = NSString(bytes: pendingByteBuffer.bytes, length: length, encoding: encoding) {
                pendingByteBuffer.replaceBytesInRange(NSMakeRange(0, length), withBytes: [])
                
                let swiftString = string as String
                characters.appendContentsOf(swiftString.characters)
                break
            } else {
                length--
            }
        }
        
        // we want to guarantee that the BOM is removed from the buffer for next time
        pendingByteBuffer.removePrefix(bom)
        
        // close the stream if it's done
        if input.streamStatus == .AtEnd { input.close() }
    }
    
}
