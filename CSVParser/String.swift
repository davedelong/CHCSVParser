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
        if self.isEmpty { return self }
        
        var startIndex = self.startIndex
        while Character.Whitespaces.contains(self[startIndex]) {
            startIndex = startIndex.successor()
        }
        
        var endIndex = self.endIndex.predecessor()
        while Character.Whitespaces.contains(self[endIndex]) {
            endIndex = endIndex.predecessor()
        }
        
        return self[startIndex...endIndex]
    }
    
}
