//
//  CharacterIterator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal final class CharacterIterator: IteratorProtocol {
    
    fileprivate var iterator: AnyIterator<Character>
    fileprivate var peekBuffer = Array<Character>()
    internal fileprivate(set) var currentIndex: UInt = 0
    
    init<I: IteratorProtocol>(iterator: I) where I.Element == Character {
        self.iterator = AnyIterator(iterator)
    }
    
    func next() -> Character? {
        if let n = peekBuffer.first {
            peekBuffer.removeFirst()
            currentIndex += 1
            return n
        }
        
        if let next = iterator.next() {
            currentIndex += 1
            return next
        }
        
        return nil
    }
    
    func peek(_ delta: UInt = 0) -> Character? {
        while UInt(peekBuffer.count) < delta + 1 {
            if let next = iterator.next() {
                peekBuffer.append(next)
            } else {
                break
            }
        }
        
        if UInt(peekBuffer.count) > delta {
            return peekBuffer[Int(delta)]
        }
        return nil
    }
    
    func progress(line: UInt? = nil, field: UInt? = nil) -> CSV.Progress {
        if let reporter = iterator as? ByteReporting {
            return CSV.Progress(bytesRead: reporter.bytesRead, charactersRead: currentIndex, line: line, field: field)
        }
        return CSV.Progress(bytesRead: 0, charactersRead: currentIndex, line: line, field: field)
    }
}
