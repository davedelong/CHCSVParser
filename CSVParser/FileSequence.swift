//
//  FileSequence.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

public struct FileSequence: SequenceType {
    public typealias GeneratorType = FileCharacterGenerator
    
    private let file: NSURL
    private let encoding: NSStringEncoding
    
    public init(file: NSURL, encoding: NSStringEncoding = NSMacOSRomanStringEncoding) {
        self.file = file
        self.encoding = encoding
    }
    
    public func generate() -> GeneratorType {
        let stream = NSInputStream(URL: file) ?? NSInputStream()
        return FileCharacterGenerator(inputStream: stream, encoding: encoding)
    }
    
}
