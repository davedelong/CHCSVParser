//
//  NSStringEncoding.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

extension String.Encoding {
    
    internal var bom: Data {
        guard let aData = "a".data(using: self) else { return Data() }
        guard let aaData = "aa".data(using: self) else { return Data() }
        guard aData.count * 2 != aaData.count else { return Data() }
        
        let aLength = aaData.count - aData.count
        let bomLength = aData.count - aLength
        let bomRange: Range<Data.Index> = 0 ..< bomLength
        return aData.subdata(in: bomRange)
    }
    
}
