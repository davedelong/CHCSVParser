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
    
    public static let Newlines: Set<Character> = ["\u{000a}",
        "\u{000b}",
        "\u{000c}",
        "\u{000d}",
        "\u{0085}",
        "\u{2028}",
        "\u{2029}"]
    public static let Whitespaces: Set<Character> = ["\u{0020}",
        "\u{0009}",
        "\u{00a0}",
        "\u{1680}",
        "\u{2000}",
        "\u{2001}",
        "\u{2002}",
        "\u{2003}",
        "\u{2004}",
        "\u{2005}",
        "\u{2006}",
        "\u{2007}",
        "\u{2008}",
        "\u{2009}",
        "\u{200a}",
        "\u{200b}",
        "\u{202f}",
        "\u{205f}",
        "\u{3000}"]
}
