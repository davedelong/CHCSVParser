//
//  CharacterStream.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal class CharacterStream<G: GeneratorType where G.Element == Character>: GeneratorType {
    
    private var generator: G
    private var peekBuffer = Array<Character>()
    internal private(set) var currentIndex: UInt = 0
    
    init<S: SequenceType where S.Generator == G>(sequence: S) {
        self.generator = sequence.generate()
    }
    
    func next() -> Character? {
        if let n = peekBuffer.first {
            peekBuffer.removeFirst()
            currentIndex++
            return n
        }
        
        if let next = generator.next() {
            currentIndex++
            return next
        }
        
        return nil
    }
    
    func peek(delta: Int = 0) -> Character? {
        guard delta >= 0 else { fatalError("Implementation flaw; peek delta cannot be negative") }
        while peekBuffer.count < delta + 1 {
            if let next = generator.next() {
                peekBuffer.append(next)
            } else {
                break
            }
        }
        
        if peekBuffer.count > delta {
            return peekBuffer[delta]
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
