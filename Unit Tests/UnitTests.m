//
//  UnitTests.m
//  CHCSVParser
/**
 Copyright (c) 2010 Dave DeLong
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 **/

#import "UnitTests.h"
#import "UnitTestContent.h"
#import "CHCSVParser.h"

@implementation UnitTests

- (void)testSimple {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testEmptyFields {
    NSString *csv = COMMA COMMA;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[@"", @"", @""]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSimpleWithInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSimpleWithDoubledInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testInterspersedDoubleQuotes {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSimpleQuoted {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[QUOTED_FIELD1, QUOTED_FIELD2, QUOTED_FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSimpleQuotedSanitized {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsSanitizesFields];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSimpleMultiline {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3], @[FIELD1, FIELD2, FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSanitizedQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsSanitizesFields];
    NSArray *expected = @[@[FIELD1, FIELD2 COMMA FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testQuotedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE], @[FIELD2]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSanitizedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsSanitizesFields];
    NSArray *expected = @[@[FIELD1, MULTILINE_FIELD], @[FIELD2]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testTrimmedWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsStripsLeadingAndTrailingWhitespace];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testSanitizedQuotedWhitespace {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE SPACE SPACE SPACE FIELD2 DOUBLEQUOTE COMMA DOUBLEQUOTE FIELD3 SPACE SPACE SPACE DOUBLEQUOTE;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsSanitizesFields];
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testUnrecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1], @[OCTOTHORPE FIELD2]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testRecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *parsed = [csv CSVComponentsWithOptions:CHCSVParserOptionsRecognizesComments];
    NSArray *expected = @[@[FIELD1]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

- (void)testTrailingNewline {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE;
    NSArray *parsed = [csv CSVComponents];
    NSArray *expected = @[@[FIELD1, FIELD2]];
    STAssertEqualObjects(parsed, expected, @"failed");
}

@end
