//
//  NSStringEncoding.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

extension NSStringEncoding {
    
    internal var bom: NSData {
        guard let aData = "a".dataUsingEncoding(self) else { return NSData() }
        guard let aaData = "aa".dataUsingEncoding(self) else { return NSData() }
        guard aData.length * 2 != aaData.length else { return NSData() }
        
        let aLength = aaData.length - aData.length
        let bomLength = aData.length - aLength
        let bomRange = NSMakeRange(0, bomLength)
        return aData.subdataWithRange(bomRange)
    }
    
}
