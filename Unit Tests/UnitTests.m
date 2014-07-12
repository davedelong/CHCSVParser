//
//  UnitTests.m
//  CHCSVParser
/**
 Copyright (c) 2014 Dave DeLong
 
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

#define TEST_ARRAYS(_actual, _expected) do {\
XCTAssertEqualObjects(_actual, _expected, @"failed"); \
} while(0)

#define TEST(_csv, _expected, ...) do {\
NSUInteger _optionList[] = {0, ##__VA_ARGS__}; \
NSUInteger _option = _optionList[(sizeof(_optionList)/sizeof(NSUInteger)) == 2 ? 1 : 0]; \
NSArray *_parsed = [(_csv) CSVComponentsWithOptions:(_option)]; \
TEST_ARRAYS(_parsed, _expected); \
} while(0)

@implementation UnitTests

- (void)testSimple {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleUTF8 {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3, UTF8FIELD4], @[FIELD1, FIELD2, FIELD3, UTF8FIELD4]];
    TEST(csv, expected);
}

- (void)testGithubIssue38 {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE OCTOTHORPE;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesComments);
}

- (void)testGithubIssue50 {
    NSString *csv = @"TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id";
    NSArray *expected = @[@[@"TRẦN",@"species_code",@"Scientific name",@"Author name",@"Common name",@"Family",@"Description",@"Habitat",@"\"Leaf size min (cm, 0 decimal digit)\"",@"\"Leaf size max (cm, 0 decimal digit)\"",@"Distribution",@"Current National Conservation Status",@"Growth requirements",@"Horticultural features",@"Uses",@"Associated fauna",@"Reference",@"species_id"]];
    TEST(csv, expected);
}

- (void)testGithubIssue50Workaround {
    NSString *csv = @"TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id";
    
    NSString *file = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    [csv writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
    
    NSArray *actual = [NSArray arrayWithContentsOfCSVURL:[NSURL fileURLWithPath:file]];
    
    NSArray *expected = @[@[@"TRẦN",@"species_code",@"Scientific name",@"Author name",@"Common name",@"Family",@"Description",@"Habitat",@"\"Leaf size min (cm, 0 decimal digit)\"",@"\"Leaf size max (cm, 0 decimal digit)\"",@"Distribution",@"Current National Conservation Status",@"Growth requirements",@"Horticultural features",@"Uses",@"Associated fauna",@"Reference",@"species_id"]];
    XCTAssertEqualObjects(actual, expected, @"failed");
}

- (void)testGithubIssue53 {
    NSString *csv = @"F1,F2,F3" NEWLINE @"a, \"b, B\",c" NEWLINE @"A,B,C" NEWLINE @"1,2,3" NEWLINE @"I,II,III";
    NSArray *expected = @[@[@"F1",@"F2",@"F3"], @[@"a", @" \"b, B\"", @"c"], @[@"A", @"B", @"C"], @[@"1", @"2", @"3"], @[@"I", @"II", @"III"]];
    TEST(csv, expected);
}

- (void)testGithubIssue65 {
    NSString *csv = FIELD1 @"æ" COMMA FIELD2 @"ø" COMMA FIELD3 @"å";
    NSArray *expected = @[@[FIELD1 @"æ", FIELD2 @"ø", FIELD3 @"å"]];
    TEST(csv, expected);
    
    NSArray *csvComponents = [csv CSVComponents];
    TEST_ARRAYS(csvComponents, expected);
}

- (void)testEmptyFields {
    NSString *csv = COMMA COMMA;
    NSArray *expected = @[@[EMPTY, EMPTY, EMPTY]];
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
    NSArray *expected = @[@[FIELD1, FIELD2], @[SPACE]];
    TEST(csv, expected);
}

- (void)testTrailingTrimmedSpace {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2], @[EMPTY]];
    TEST(csv, expected, CHCSVParserOptionsTrimsWhitespace);
}

- (void)testEmoji {
    NSString *csv = @"1️⃣,2️⃣,3️⃣,4️⃣,5️⃣" NEWLINE @"6️⃣,7️⃣,8️⃣,9️⃣,0️⃣";
    NSArray *expected = @[@[@"1️⃣",@"2️⃣",@"3️⃣",@"4️⃣",@"5️⃣"],@[@"6️⃣",@"7️⃣",@"8️⃣",@"9️⃣",@"0️⃣"]];
    TEST(csv, expected);
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

#pragma mark - Testing First Line as Keys

- (void)testOrderedDictionary {
    CHCSVOrderedDictionary *dictionary = [CHCSVOrderedDictionary dictionaryWithObjects:@[FIELD1, FIELD2, FIELD3] forKeys:@[FIELD1, FIELD2, FIELD3]];
    NSArray *expected = @[FIELD1, FIELD2, FIELD3];
    XCTAssertEqualObjects(dictionary.allKeys, expected, @"Unexpected field order");
    
    XCTAssertEqualObjects(dictionary[0], FIELD1, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[1], FIELD2, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[2], FIELD3, @"Unexpected field");
    
    XCTAssertEqualObjects(dictionary[FIELD1], FIELD1, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[FIELD2], FIELD2, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[FIELD3], FIELD3, @"Unexpected field");
    
    NSDictionary *regularDictionary = @{FIELD1 : FIELD1, FIELD2 : FIELD2, FIELD3 : FIELD3 };
    XCTAssertNotEqualObjects(regularDictionary, expected, @"Somehow equal??");
}

- (void)testFirstLineAsKeys {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[
                          [CHCSVOrderedDictionary dictionaryWithObjects:@[FIELD1, FIELD2, FIELD3] forKeys:@[FIELD1, FIELD2, FIELD3]]
                          ];
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
}

- (void)testFirstLineAsKeys_SingleLine {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE;
    NSArray *expected = @[];
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
    
    csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
}

- (void)testFirstLineAsKeys_MismatchedFieldCount {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA FIELD1;
    
    NSError *error = nil;
    (void)[csv componentsSeparatedByDelimiter:[COMMA characterAtIndex:0] options:CHCSVParserOptionsUsesFirstLineAsKeys error:&error];
    XCTAssertNotNil(error, @"Expected error");
    XCTAssertEqualObjects(error.domain, CHCSVErrorDomain, @"Unexpected error");
    XCTAssertEqual(error.code, CHCSVErrorCodeIncorrectNumberOfFields, @"Unexpected error");
}

#pragma mark - Testing Valid Delimiters

- (void)testAllowedDelimiter_Octothorpe {
    NSString *csv = FIELD1 OCTOTHORPE FIELD2 OCTOTHORPE FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'#'];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Octothorpe {
    NSString *csv = FIELD1 OCTOTHORPE FIELD2 OCTOTHORPE FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'#' options:CHCSVParserOptionsRecognizesComments], @"failed");
}

- (void)testAllowedDelimiter_Backslash {
    NSString *csv = FIELD1 BACKSLASH FIELD2 BACKSLASH FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'\\'];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Backslash {
    NSString *csv = FIELD1 BACKSLASH FIELD2 BACKSLASH FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'\\' options:CHCSVParserOptionsRecognizesBackslashesAsEscapes], @"failed");
}

- (void)testAllowedDelimiter_Equal {
    NSString *csv = FIELD1 EQUAL FIELD2 EQUAL FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'='];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Equal {
    NSString *csv = FIELD1 EQUAL FIELD2 EQUAL FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'=' options:CHCSVParserOptionsRecognizesLeadingEqualSign], @"failed");
}

#pragma mark - Testing Leading Equal

- (void)testLeadingEqual {
    NSString *csv = FIELD1 COMMA EQUAL QUOTED_FIELD2 COMMA EQUAL QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, EQUAL QUOTED_FIELD2, EQUAL QUOTED_FIELD3]];
    
    TEST(csv, expected, CHCSVParserOptionsRecognizesLeadingEqualSign);
}

- (void)testSanitizedLeadingEqual {
    NSString *csv = FIELD1 COMMA EQUAL QUOTED_FIELD2 COMMA EQUAL QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST(csv, expected, CHCSVParserOptionsRecognizesLeadingEqualSign | CHCSVParserOptionsSanitizesFields);
}

@end
