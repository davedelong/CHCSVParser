//
//  CHCSVParserBlocksTestCase.m
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


#import <XCTest/XCTest.h>

#import "CHCSVParserBlocks.h"

@interface CHCSVParserBlocksTestCase : XCTestCase

@property (nonatomic, strong) CHCSVParserBlocks *parser;

@end

@implementation CHCSVParserBlocksTestCase

#pragma mark - Setup methods

- (void)setUp {
    [super setUp];
    NSString *csv = @"1,2,3,4,5";
    self.parser = [[CHCSVParserBlocks alloc] initWithCSVString:csv];
}

- (void)tearDown {
    self.parser = nil;
    [super tearDown];
}

#pragma mark - Test callbacks

- (void)testCallbacksNotSet {
    XCTAssertNoThrow([self.parser parse]);
}

- (void)testValidateDidBeginCallback {
    __block BOOL wasCalled = NO;
    self.parser.didBeginDocumentCallback = ^{
        wasCalled = YES;
    };
    [self.parser.delegate parserDidBeginDocument:self.parser];
    XCTAssertTrue(wasCalled, @"didBeginLineCallback not called!");
}

- (void)testValidateDidEndDocumentCallback {
    __block BOOL wasCalled = NO;
    self.parser.didEndDocumentCallback = ^ {
        wasCalled = YES;
    };
    [self.parser.delegate parserDidEndDocument:self.parser];
    XCTAssertTrue(wasCalled, @"parserDidEndDocument not called!");
}

- (void)testValidateDidBeginLineCallback {
    __block BOOL wasCalled = NO;
    __block NSUInteger receivedRecordNumber;
    NSUInteger recordNumber = arc4random();
    self.parser.didBeginLineCallback = ^(NSUInteger aRecordNumber) {
        wasCalled = YES;
        receivedRecordNumber = aRecordNumber;
    };
    [self.parser.delegate parser:self.parser didBeginLine:recordNumber];
    XCTAssertTrue(wasCalled, @"didBeginLineCallback not called!");
    XCTAssertEqual(recordNumber, receivedRecordNumber);
}

- (void)testValidateDidEndLineCallback {
    __block BOOL wasCalled = NO;
    __block NSUInteger receivedRecordNumber;
    NSUInteger recordNumber = arc4random();
    self.parser.didEndLineCallback = ^(NSUInteger aRecordNumber) {
        wasCalled = YES;
        receivedRecordNumber = aRecordNumber;
    };
    [self.parser.delegate parser:self.parser didEndLine:recordNumber];
    XCTAssertTrue(wasCalled, @"didEndLineCallback not called!");
    XCTAssertEqual(recordNumber, receivedRecordNumber);
}

- (void)testValidateDidReadFieldCallback {
  __block BOOL wasCalled = NO;
  __block NSString *receivedField;
  __block NSInteger receivedLine;
  NSString *field = [[self class] randomString];
  NSInteger line = arc4random();
  self.parser.didReadFieldCallback = ^(NSString *aField, NSInteger aLine) {
      wasCalled = YES;
      receivedField = aField;
      receivedLine = aLine;
  };
  [self.parser.delegate parser:self.parser didReadField:field atIndex:line];
  XCTAssertTrue(wasCalled, @"didReadFieldCallback not called!");
  XCTAssertEqualObjects(field, receivedField);
  XCTAssertEqual(line, receivedLine);
}

- (void)testValidateDidReadCommentCallback {
    __block BOOL wasCalled = NO;
    __block NSString *receivedComment;
    NSString *comment = [[self class] randomString];
    self.parser.didReadCommentCallback = ^(NSString *aComment) {
        wasCalled = YES;
        receivedComment = aComment;
    };
    [self.parser.delegate parser:self.parser didReadComment:comment];
    XCTAssertTrue(wasCalled, @"didReadCommentCallback not called!");
    XCTAssertEqualObjects(comment, receivedComment);
}

- (void)testValidateDidFailedWithErrorCallback {
    __block BOOL wasCalled = NO;
    __block NSError *receivedError;
    NSString *randomDomain = [[self class] randomString];
    NSUInteger randomCode = arc4random();
    NSError *error = [NSError errorWithDomain:randomDomain code:randomCode userInfo:nil];
    self.parser.didFailWithErrorCallback = ^(NSError *aError) {
        wasCalled = YES;
        receivedError = aError;
    };
    [self.parser.delegate parser:self.parser didFailWithError:error];
    XCTAssertTrue(wasCalled, @"didFailWithErrorCallback not called!");
    XCTAssertEqualObjects(error, receivedError);
}

#pragma mark - Factory methods

+ (NSString *)randomString {
    return [NSString stringWithFormat:@"%c", arc4random_uniform(26) + 'a'];
}

@end
