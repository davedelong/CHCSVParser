//
//  FileCharacterGenerator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

private let PageSize = 4096
private let LoadMoreThreshold = 1024

public class FileCharacterGenerator: GeneratorType {
    public typealias Element = Character
    
    let input: NSInputStream
    let bom: NSData
    let encoding: NSStringEncoding
    
    var pendingByteBuffer = NSMutableData()
    var characters = Array<Character>()
    
    public init(file: NSURL, encoding: NSStringEncoding = NSMacOSRomanStringEncoding) {
        self.input = NSInputStream(URL: file) ?? NSInputStream()
        self.bom = encoding.bom
        self.encoding = encoding
        self.characters.reserveCapacity(PageSize + LoadMoreThreshold)
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
        
        // if we have at least 1024 characters, don't read more
        guard characters.count < LoadMoreThreshold else { return }
        guard input.hasBytesAvailable else { return }
        
        var buffer = Array<UInt8>(count: PageSize, repeatedValue: 0)
        
        let bytesRead = input.read(&buffer, maxLength: PageSize)
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
