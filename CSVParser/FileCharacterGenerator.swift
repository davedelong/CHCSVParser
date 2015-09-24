//
//  FileCharacterGenerator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

private let DefaultPageSize = 4096
private let DefaultLoadMoreThreshold = 1024

public class FileCharacterGenerator: GeneratorType {
    public typealias Element = Character
    
    private let input: NSInputStream
    private let bom: NSData
    private let encoding: NSStringEncoding
    
    private let pageSize: Int
    private let loadMoreThreshold: Int
    private var pendingByteBuffer = NSMutableData()
    private var characters = Array<Character>()
    
    public init(file: NSURL, encoding: NSStringEncoding = NSMacOSRomanStringEncoding, pageSize: Int = 4096, loadThreshold: Int = 1024) {
        
        self.input = NSInputStream(URL: file) ?? NSInputStream()
        self.bom = encoding.bom
        self.encoding = encoding
        
        let page = pageSize > 0 ? pageSize : DefaultPageSize
        let threshold = loadThreshold > 0 ? loadThreshold : DefaultLoadMoreThreshold
        
        self.pageSize = max(page, threshold)
        self.loadMoreThreshold = min(page, threshold)
        
        self.characters.reserveCapacity(self.pageSize + self.loadMoreThreshold)
    }
    
    deinit {
        if input.streamStatus != .Closed { input.close() }
    }
    
    public func next() -> Element? {
        readMoreIfNecessary()
        if characters.count == 0 { return nil }
        return characters.removeFirst()
    }
    
    private func readMoreIfNecessary() {
        if input.streamStatus == .NotOpen {
            input.open()
        }
        
        if input.streamStatus == .AtEnd || input.streamStatus == .Closed || input.streamStatus == .Error { return }
        
        // we only want to try to load more if we have fewer than 1024 characters
        guard characters.count < loadMoreThreshold else { return }
        guard input.hasBytesAvailable else { return }
        
        var buffer = Array<UInt8>(count: pageSize, repeatedValue: 0)
        
        let bytesRead = input.read(&buffer, maxLength: pageSize)
        pendingByteBuffer.appendBytes(buffer, length: bytesRead)
        
        guard pendingByteBuffer.length > 0 else { return }
        
        if bom.length > 0 {
            pendingByteBuffer.replaceBytesInRange(NSMakeRange(0, 0), withBytes: bom.bytes)
        }
        
        
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
        
        pendingByteBuffer.removePrefix(bom)
        
        if input.streamStatus == .AtEnd {
            input.close()
        }
    }
    
}
