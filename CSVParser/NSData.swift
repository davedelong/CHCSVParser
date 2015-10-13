//
//  NSData.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/23/15.
//
//

import Foundation

extension NSData {
    
    internal func hasPrefix(prefix: NSData) -> Bool {
        guard length >= prefix.length else { return false }
        
        // the guard statement already guaranteed prefix.length < self.length
        let searchRange = NSMakeRange(0, prefix.length)
        
        let range = rangeOfData(prefix, options: .Anchored, range: searchRange)
        return range.location == 0 // return true iff the prefix was found at the start
    }
    
}

extension NSMutableData {
    
    internal func insertPrefix(prefix: NSData) {
        guard prefix.length > 0 else { return }
        replaceBytesInRange(NSMakeRange(0, 0), withBytes: prefix.bytes)
    }
    
    internal func removePrefix(prefix: NSData) {
        guard prefix.length > 0 else { return }
        guard hasPrefix(prefix) else { return }
        replaceBytesInRange(NSMakeRange(0, prefix.length), withBytes: [])
    }
    
}
