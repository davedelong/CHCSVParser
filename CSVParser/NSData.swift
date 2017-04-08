//
//  NSData.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/23/15.
//
//

import Foundation

extension Data {
    
    internal func hasPrefix(_ prefix: Data) -> Bool {
        guard count >= prefix.count else { return false }
        
        // the guard statement already guaranteed prefix.length < self.length
        guard let range = self.range(of: prefix, options: .anchored, in: 0 ..< prefix.count) else { return false }
        return range.lowerBound == 0 // return true iff the prefix was found at the start
    }
    
    internal func removing(prefix: Data) -> Data {
        guard hasPrefix(prefix) else { return self }
        
        let range: Range<Data.Index> = prefix.count ..< (self.count - prefix.count)
        
        return subdata(in: range)
    }
    
}

extension NSMutableData {
    
    internal func hasPrefix(_ prefix: Data) -> Bool {
        return (self as Data).hasPrefix(prefix)
    }
    
    internal func insert(prefix: Data) {
        guard prefix.count > 0 else { return }
        let nsData = prefix as NSData
        replaceBytes(in: NSRange(location: 0, length: 0), withBytes: nsData.bytes, length: nsData.length)
    }
    
    internal func remove(prefix: Data) {
        guard prefix.count > 0 else { return }
        guard hasPrefix(prefix) else { return }
        replaceBytes(in: NSRange(location: 0, length: prefix.count), withBytes: [], length: 0)
    }
    
}
