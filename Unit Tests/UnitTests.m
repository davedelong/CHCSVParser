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

#define TEST(_csv, _expected, ...) do {\
NSUInteger _optionList[] = {0, ##__VA_ARGS__}; \
NSUInteger _option = _optionList[(sizeof(_optionList)/sizeof(NSUInteger)) == 2 ? 1 : 0]; \
NSArray *_parsed = [(_csv) CSVComponentsWithOptions:(_option)]; \
STAssertEqualObjects(_parsed, _expected, @"failed"); \
} while(0)

@implementation UnitTests

- (void)testSimple {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected);
}

- (void)testEmptyFields {
    NSString *csv = COMMA COMMA;
    NSArray *expected = @[@[@"", @"", @""]];
    TEST(csv, expected);
}

- (void)testSimpleWithInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleWithDoubledInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3]];
    TEST(csv, expected);
}

- (void)testInterspersedDoubleQuotes {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE]];
    TEST(csv, expected);
}

- (void)testSimpleQuoted {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *expected = @[@[QUOTED_FIELD1, QUOTED_FIELD2, QUOTED_FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleQuotedSanitized {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testSimpleMultiline {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3], @[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected);
}

- (void)testQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE]];
    TEST(csv, expected);
}

- (void)testSanitizedQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, FIELD2 COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testQuotedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE], @[FIELD2]];
    TEST(csv, expected);
}

- (void)testSanitizedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *expected = @[@[FIELD1, MULTILINE_FIELD], @[FIELD2]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    TEST(csv, expected);
}

- (void)testTrimmedWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsTrimsWhitespace);
}

- (void)testSanitizedQuotedWhitespace {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE SPACE SPACE SPACE FIELD2 DOUBLEQUOTE COMMA DOUBLEQUOTE FIELD3 SPACE SPACE SPACE DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testUnrecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *expected = @[@[FIELD1], @[OCTOTHORPE FIELD2]];
    TEST(csv, expected);
}

- (void)testRecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *expected = @[@[FIELD1]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesComments);
}

- (void)testTrailingNewline {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE;
    NSArray *expected = @[@[FIELD1, FIELD2]];
    TEST(csv, expected);
}

- (void)testTrailingSpace {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2], @[@" "]];
    TEST(csv, expected);
}

- (void)testTrailingTrimmedSpace {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2], @[@""]];
    TEST(csv, expected, CHCSVParserOptionsTrimsWhitespace);
}

#pragma mark - Testing Backslashes

- (void)testUnrecognizedBackslash {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH, FIELD3]];
    TEST(csv, expected);
}

- (void)testBackslashEscapedComma {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes);
}

- (void)testSantizedBackslashEscapedComma {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes | CHCSVParserOptionsSanitizesFields);
}

- (void)testBackslashEscapedNewline {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH NEWLINE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH NEWLINE FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes);
}

- (void)testSantizedBackslashEscapedNewline {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH NEWLINE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 NEWLINE FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes | CHCSVParserOptionsSanitizesFields);
}

@end
