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
#import "CHCSVParser.h"

@implementation UnitTests

- (void) setUp {
	testPool = [[NSAutoreleasePool alloc] init];
}

- (void) tearDown {
	[testPool drain], testPool = nil;
}

- (NSArray *) expectedFields {
	return @[
    @[@"This",@"is",@"a",@"simple",@"line"],
    @[@"This",@"is",@"a",@"quoted",@"line"],
    @[@"This",@"is",@"a",@"mixed",@"line"],
    @[@"This",@"has",@"a\nmultiline\nfield"],
    @[@"This",@"has",@"single",@"apostrophes",@"ma'am"],
    @[@"#This",@"line",@"should",@"not",@"be",@"ignored"],
    @[@"This",@"has",@"\"escaped\"",@"quotes"],
    @[@"This",@"has",@"\"escaped\"",@"quotes"],
    @[@"This",@"has",@"empty",@"fields",@"",@"",@""],
    @[@"This",@"has",@"escaped",@"escapes\\"],
    @[@"This",@"has",@"escaped",@"commas,"],
    @[@"This",@"has",@"quoted",@"commas,"],
    @[@"This",@"has",@"empty",@"quoted",@"fields",@"",@""],
    @[@"This",@"has",@"mixed",@"\"escaped quotes\""],
    @[@"   This   ",@"   line   ",@"   has   ",@"   significant   ",@"   whitespace   "],
    @[@"This",@"is",@"the",@"last",@"line"],
    @[@""]
    ];
}

- (void) testCSV {
	NSString *file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	
	NSArray *fields = [NSArray arrayWithContentsOfCSVFile:file options:CHCSVParserOptionsRecognizesBackslashesAsEscapes];
	NSLog(@"read: %@", fields);
	
	NSArray *expectedFields = [self expectedFields];
	
	NSUInteger expectedCount = [expectedFields count];
	NSUInteger actualCount = [fields count];
	STAssertTrue(expectedCount == actualCount, @"incorrect number of lines parsed.  expected %lu, given %lu", expectedCount, actualCount);
	for (int i = 0; i < MIN(expectedCount, actualCount); ++i) {
		NSArray *actualLine = [fields objectAtIndex:i];
		NSArray *expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([actualLine isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, actualLine);
	}
	
	NSString *tempFileName = [NSString stringWithFormat:@"%d-test.csv", arc4random()];
	NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
	NSLog(@"Writing to file: %@", tempFile);
    
    NSOutputStream *output = [NSOutputStream outputStreamToFileAtPath:tempFile append:NO];
    CHCSVWriter *writer = [[CHCSVWriter alloc] initWithOutputStream:output encoding:NSUTF8StringEncoding delimiter:','];
    for (NSArray *line in expectedFields) {
        [writer writeLineOfFields:line];
    }
    [writer closeStream];
    
	NSArray *readFromFile = [NSArray arrayWithContentsOfCSVFile:tempFile];
	
	NSUInteger readCount = [readFromFile count];
	STAssertTrue(readCount == expectedCount, @"Incorrect number of lines read.  Expected %lu, read %lu", expectedCount, readCount);
	
	for (int i = 0; i < MIN(expectedCount, readCount); ++i) {
		NSArray *readLine = [readFromFile objectAtIndex:i];
		NSArray *expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([expectedLine isEqualToArray:readLine], @"lines differ.  Expected %@, read %@", expectedLine, readLine);
	}
}

- (void) testCSVString {
	NSString *file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	
	NSStringEncoding encoding = 0;
	NSString *csv = [NSString stringWithContentsOfFile:file usedEncoding:&encoding error:nil];
	NSArray *fields = [csv CSVComponents];
	NSLog(@"fields: %@", fields);
	
	NSArray *expectedFields = [self expectedFields];
	
	NSUInteger expectedCount = [expectedFields count];
	NSUInteger actualCount = [fields count];
	STAssertTrue(expectedCount == actualCount, @"incorrect number of lines parsed.  expected %lu, given %lu", expectedCount, actualCount);
	for (int i = 0; i < MIN(expectedCount, actualCount); ++i) {
		NSArray *actualLine = [fields objectAtIndex:i];
		NSArray *expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([actualLine isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, actualLine);
	}
}

@end
