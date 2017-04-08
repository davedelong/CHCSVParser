//
//  StreamCharacterIterator.swift
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

public final class StreamCharacterIterator: IteratorProtocol, ByteReporting {
    public typealias Element = Character
    
    private let input: InputStream
    private let bom: Data
    private let encoding: String.Encoding
    
    private let pageSize: Int
    private let loadMoreThreshold: Int
    private var pendingByteBuffer = NSMutableData()
    private var characters = Array<Character>()
    
    open fileprivate(set) var bytesRead: UInt
    
    public init(inputStream: InputStream, encoding: String.Encoding = String.Encoding.macOSRoman, pageSize: Int = 4096, loadThreshold: Int = 1024) {
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
        if input.streamStatus != .closed { input.close() }
    }
    
    open func next() -> Element? {
        readMoreIfNecessary()
        if characters.isEmpty { return nil }
        return characters.removeFirst()
    }
    
    fileprivate func readMoreIfNecessary() {
        // we only want to try to load more if we have fewer than 1024 characters
        guard characters.count < loadMoreThreshold else { return }
        
        // open the stream
        if input.streamStatus == .notOpen { input.open() }
        
        // make sure the stream is open for reading
        guard [.opening, .open, .reading].contains(input.streamStatus) else { return }
        
        // we can only read from the stream if it has something to be read
        guard input.hasBytesAvailable else { return }
        
        var buffer = Array<UInt8>(repeating: 0, count: pageSize)
        let bytesRead = input.read(&buffer, maxLength: pageSize)
        
        self.bytesRead += UInt(bytesRead)
        pendingByteBuffer.append(buffer, length: bytesRead)
        
        guard pendingByteBuffer.length > 0 else { return }
        
        if bom.count > 0 && pendingByteBuffer.hasPrefix(bom) == false {
            // this encoding may require a BOM in order to parse correctly
            // insert the bom into the byte buffer
            pendingByteBuffer.insert(prefix: bom)
        }
        
        // try to convert as much of the pendingByteBuffer as possible into a String
        var length = pendingByteBuffer.length
        while length > bom.count {
            if let string = NSString(bytes: pendingByteBuffer.bytes, length: length, encoding: encoding.rawValue) {
                pendingByteBuffer.replaceBytes(in: NSRange(location: 0, length: length), withBytes: [], length: 0)
                
                let swiftString = string as String
                characters.append(contentsOf: swiftString.characters)
                break
            } else {
                length -= 1
            }
        }
        
        // we want to guarantee that the BOM is removed from the buffer for next time
        pendingByteBuffer.remove(prefix: bom)
        
        // close the stream if it's done
        if input.streamStatus == .atEnd { input.close() }
    }
    
}
