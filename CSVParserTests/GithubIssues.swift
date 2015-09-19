//
//  GithubIssues.swift
//  CHCSVParser
//
//  Created by Dave DeLong on 9/19/15.
//
//

import XCTest
import CSVParser

class GithubIssues: XCTestCase {
    
    func testGithubIssue35() {
        let tsv = "1,a\t1,b\t1,c\t1,\"d\"\n" + "2,a\t2,b\t2,c\t2,d\n" + "3,a\t3,b\t3,c\t3,d\n" + "4,a\t4,b\t4,c\t4,d\n" + "5,a\t5,b\t5,c\t5,d\n" + "6,a\t6,b\t6,c\t6,d\n" + "7,a\t7,b\t7,c\t7,d\n" + "8,a\t8,b\t8,c\t8,d\n" + "9,a\t9,b\t9,c\t9,d\n" + "10,a\t10,b\t10,c\t10,d"
        
        let expected: Array<CSVRecord> = [
            ["1,a", "1,b", "1,c", "1,\"d\""],
            ["2,a", "2,b", "2,c", "2,d"],
            ["3,a", "3,b", "3,c", "3,d"],
            ["4,a", "4,b", "4,c", "4,d"],
            ["5,a", "5,b", "5,c", "5,d"],
            ["6,a", "6,b", "6,c", "6,d"],
            ["7,a", "7,b", "7,c", "7,d"],
            ["8,a", "8,b", "8,c", "8,d"],
            ["9,a", "9,b", "9,c", "9,d"],
            ["10,a", "10,b", "10,c", "10,d"],
        ]
        
        parse(tsv, expected, configuration: CSVParserConfiguration(delimiter: "\t"))
    }
    
    func testGithubIssue38() {
        let csv = "\(Field1),\(Field2),\(Field3)\n#"
        let expected: Array<CSVRecord> = [[Field1, Field2, Field3], []]
        var config = CSVParserConfiguration()
        config.recognizeComments = true
        parse(csv, expected, configuration: config)
    }
    
    func testGithubIssue50() {
        let csv = "TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id"
        let expected: Array<CSVRecord> = [["TRẦN","species_code","Scientific name","Author name","Common name","Family","Description","Habitat","\"Leaf size min (cm, 0 decimal digit)\"","\"Leaf size max (cm, 0 decimal digit)\"","Distribution","Current National Conservation Status","Growth requirements","Horticultural features","Uses","Associated fauna","Reference","species_id"]]
        parse(csv, expected)
    }
    
    func testGithubIssue53() {
        let csv = "F1,F2,F3\n" + "a, \"b, B\",c\n" + "A,B,C\n" + "1,2,3\n" + "I,II,III"
        let expected: Array<CSVRecord> = [
            ["F1", "F2", "F3"],
            ["a", " \"b, B\"", "c"],
            ["A", "B", "C"],
            ["1", "2", "3"],
            ["I", "II", "III"]
        ]
        parse(csv, expected)
    }

}
