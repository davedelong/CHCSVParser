//
//  ScenarioTests.swift
//  CSV
//
//  Created by Dave DeLong on 4/9/17.
//
//

import XCTest
import CSV

class ScenarioTest: XCTestCase {
    
    override static func defaultTestSuite() -> XCTestSuite {
        let suite = XCTestSuite(name: "Scenarios")
        addTests(name: "Simple", scenarios: simpleScenarios, to: suite)
        addTests(name: "Quoted", scenarios: quotedScenarios, to: suite)
        addTests(name: "Comment", scenarios: commentScenarios, to: suite)
        addTests(name: "Trailing Whitespace", scenarios: trailingWhitespaceScenarios, to: suite)
        addTests(name: "Emoji", scenarios: emojiScenarios, to: suite)
        addTests(name: "Backslash", scenarios: backslashScenarios, to: suite)
        return suite
    }
    
    private static func addTests(name: String, scenarios: Array<Scenario>, to suite: XCTestSuite) {
        let subSuite = XCTestSuite(name: name)
        for scenario in scenarios {
            let p = XCTestCase(category: name, testName: scenario.name + "-Parse", block: {
                scenario.testParser()
            })
            suite.addTest(p)
            
            let w = XCTestCase(category: name, testName: scenario.name + "-Write", block: {
                scenario.testWriter()
            })
            suite.addTest(w)
        }
        suite.addTest(subSuite)
    }
}
