//
//  Character.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import Foundation

extension Character {
    static let DoubleQuote: Character = "\""
    static let Backslash: Character = "\\"
    static let Octothorpe: Character = "#"
    static let Equal: Character = "="
    
    var isNewline: Bool {
        switch self {
        case "\u{000a}"..."\u{000d}": return true
        case "\u{0085}": return true
        case "\u{2028}": return true
        case "\u{2029}": return true
        default: return false
        }
    }
    
    var isWhitespace: Bool {
        switch self {
        case "\u{0020}": return true
        case "\u{0009}": return true
        case "\u{00a0}": return true
        case "\u{1680}": return true
        case "\u{2000}"..."\u{200b}": return true
        case "\u{202f}": return true
        case "\u{205f}": return true
        case "\u{3000}": return true
        default: return false
        }
    }
}
