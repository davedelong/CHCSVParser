//
//  PeekingGenerator.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

internal class PeekingGenerator<E> {
    typealias Element = E
    
    private var generator: AnyGenerator<E>
    private var peekBuffer = Array<E>()
    internal private(set) var currentIndex: UInt = 0
    
    init<S: SequenceType where S.Generator.Element == E>(sequence: S) {
        self.generator = AnySequence(sequence).generate()
    }
    
    func next() -> Element? {
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
    
    func peek(delta: Int = 0) -> Element? {
        guard delta >= 0 else { fatalError("delta cannot be negative") }
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
    
}
