//
//  CharacterIterator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal final class CharacterIterator: IteratorProtocol {
    
    fileprivate var generator: AnyIterator<Character>
    fileprivate var peekBuffer = Array<Character>()
    internal fileprivate(set) var currentIndex: UInt = 0
    
    init(sequence: AnySequence<Character>) {
        self.generator = AnyIterator(sequence.makeIterator())
    }
    
    func next() -> Character? {
        if let n = peekBuffer.first {
            peekBuffer.removeFirst()
            currentIndex += 1
            return n
        }
        
        if let next = generator.next() {
            currentIndex += 1
            return next
        }
        
        return nil
    }
    
    func peek(_ delta: UInt = 0) -> Character? {
        guard delta >= 0 else { fatalError("Implementation flaw; peek delta cannot be negative") }
        while UInt(peekBuffer.count) < delta + 1 {
            if let next = generator.next() {
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
    
    func progress() -> CSVProgress {
        if let reporter = generator as? ByteReporting {
            return CSVProgress(bytesRead: reporter.bytesRead, charactersRead: currentIndex)
        }
        return CSVProgress(bytesRead: 0, charactersRead: currentIndex)
    }
}
