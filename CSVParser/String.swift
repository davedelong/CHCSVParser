//
//  String.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal extension String {
    
    func trim() -> String {
        var startIndex = self.startIndex
        while self[startIndex].isWhitespace {
            startIndex = startIndex.successor()
        }
        
        var endIndex = self.endIndex
        while self[endIndex].isWhitespace {
            endIndex = endIndex.predecessor()
        }
        
        return self[startIndex...endIndex]
    }
    
}
