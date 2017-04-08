//
//  FileSequence.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/15.
//
//

import Foundation

public struct FileSequence: Sequence {
    public typealias Iterator = StreamCharacterIterator
    
    fileprivate let file: URL
    fileprivate let encoding: String.Encoding
    
    public init(file: URL, encoding: String.Encoding = String.Encoding.macOSRoman) {
        self.file = file
        self.encoding = encoding
    }
    
    public func makeIterator() -> Iterator {
        let stream = InputStream(url: file) ?? InputStream()
        return StreamCharacterIterator(inputStream: stream, encoding: encoding)
    }
    
}
