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
#import "NSArray+CHCSVAdditions.h"
#import "NSString+CHCSVAdditions.h"
#import "CHCSVParser.h"

@implementation UnitTests

- (void) setUp {
	testPool = [[NSAutoreleasePool alloc] init];
}

- (void) tearDown {
	[testPool drain], testPool = nil;
}

- (NSArray *) expectedFields {
	return [NSArray arrayWithObjects:
			[NSArray arrayWithObjects:@"This",@"is",@"a",@"simple",@"line",nil],
			[NSArray arrayWithObjects:@"This",@"is",@"a",@"quoted",@"line",nil],
			[NSArray arrayWithObjects:@"This",@"is",@"a",@"mixed",@"line",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"a\nmultiline\nfield",nil],
            [NSArray arrayWithObjects:@"This",@"has",@"single",@"apostrophes",@"ma'am",nil],
			[NSArray arrayWithObjects:@"#This",@"line",@"should",@"not",@"be",@"ignored",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"\"escaped\"",@"quotes",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"\"escaped\"",@"quotes",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"empty",@"fields",@"",@"",@"",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"escaped",@"escapes\\",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"escaped",@"commas,",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"quoted",@"commas,",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"empty",@"quoted",@"fields",@"",@"",nil],
			[NSArray arrayWithObjects:@"This",@"has",@"mixed",@"\"escaped quotes\"", nil],
			[NSArray arrayWithObjects:@"This",@"is",@"the",@"last",@"line",nil],
			nil];
}

- (void) testCSV {
	NSString * file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	
	NSStringEncoding encoding = 0;
	NSError * error = nil;
	NSArray * fields = [NSArray arrayWithContentsOfCSVFile:file usedEncoding:&encoding error:&error];
	NSLog(@"read: %@", fields);
	
	STAssertTrue(encoding == NSUTF8StringEncoding, @"Wrong encoding; given %@ (%lu)", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)), encoding);
	STAssertNil(error, @"Unexpected error: %@", error);
	
	NSArray * expectedFields = [self expectedFields];
	
	NSUInteger expectedCount = [expectedFields count];
	NSUInteger actualCount = [fields count];
	STAssertTrue(expectedCount == actualCount, @"incorrect number of lines parsed.  expected %lu, given %lu", expectedCount, actualCount);
	for (int i = 0; i < MIN(expectedCount, actualCount); ++i) {
		NSArray * actualLine = [fields objectAtIndex:i];
		NSArray * expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([actualLine isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, actualLine);
	}
	
	NSString * tempFileName = [NSString stringWithFormat:@"%d-test.csv", arc4random()];
	NSString * tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
	NSLog(@"Writing to file: %@", tempFile);

    error = nil;
	BOOL writtenToFile = [expectedFields writeToCSVFile:tempFile atomically:YES error:&error];
	
    STAssertNil(error, @"Unexpected error writing to temporary file: %@", error);
	STAssertTrue(writtenToFile, @"Unable to write to temporary file");
	
	error = nil;
	NSArray * readFromFile = [NSArray arrayWithContentsOfCSVFile:tempFile encoding:encoding error:&error];
	
	STAssertNil(error, @"Unexpected error reading from temporary file: %@", error);
	
	NSUInteger readCount = [readFromFile count];
	STAssertTrue(readCount == expectedCount, @"Incorrect number of lines read.  Expected %lu, read %lu", expectedCount, readCount);
	
	for (int i = 0; i < MIN(expectedCount, readCount); ++i) {
		NSArray * readLine = [readFromFile objectAtIndex:i];
		NSArray * expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([expectedLine isEqualToArray:readLine], @"lines differ.  Expected %@, read %@", expectedLine, readLine);
	}
}

- (void) testCSVString {
	NSString * file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	
	NSStringEncoding encoding = 0;
	NSString * csv = [NSString stringWithContentsOfFile:file usedEncoding:&encoding error:nil];
	NSArray * fields = [csv CSVComponents];
	NSLog(@"fields: %@", fields);
	
	NSArray * expectedFields = [self expectedFields];
	
	NSUInteger expectedCount = [expectedFields count];
	NSUInteger actualCount = [fields count];
	STAssertTrue(expectedCount == actualCount, @"incorrect number of lines parsed.  expected %lu, given %lu", expectedCount, actualCount);
	for (int i = 0; i < MIN(expectedCount, actualCount); ++i) {
		NSArray * actualLine = [fields objectAtIndex:i];
		NSArray * expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([actualLine isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, actualLine);
	}
}

- (void) testCSVWithBlocks {
	NSString *file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	NSStringEncoding encoding = 0;
	NSError *error = nil;
    
    __block CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:file usedEncoding:&encoding error:&error];
    
    STAssertTrue(encoding == NSUTF8StringEncoding, @"Wrong encoding; given %@ (%lu)", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)), encoding);
	STAssertNil(error, @"Unexpected error: %@", error);
    
    NSArray *expectedFields = [self expectedFields];\
    __block int expectedLineNumber = 1;
    __block int expectedFieldCount = 0;
    
    parser.didStartDocument = ^(NSString *csvFile) {
        STAssertTrue([file isEqualToString:csvFile], @"Wrong file path");
    };
    parser.didStartLine = ^(NSUInteger lineNumber) {
        STAssertTrue(expectedLineNumber == lineNumber, @"Incorrect line number. expected %lu, given %lu", expectedLineNumber, lineNumber);
        
        expectedFieldCount = 0;
    };
    parser.didEndLine = ^(NSUInteger lineNumber, NSArray *fields) {
        NSArray *expectedLine = [expectedFields objectAtIndex:lineNumber - 1];
        
        STAssertTrue(expectedLineNumber == lineNumber, @"Incorrect line number. expected %lu, given %lu", expectedLineNumber, lineNumber);
        STAssertTrue([fields isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, fields);
        
        expectedLineNumber++;
    };
    parser.didReadField = ^(NSString *field) {
        NSArray *expectedLine = [expectedFields objectAtIndex:expectedLineNumber - 1];
        NSString *expectedField = [expectedLine objectAtIndex:expectedFieldCount];
        
        STAssertTrue([expectedField isEqualToString:field], @"Incorrect field: expected %@, given %@", expectedField, field);
        
        expectedFieldCount++;
    };
    parser.didEndDocument = ^(NSString *csvFile) {
        STAssertTrue([file isEqualToString:csvFile], @"Wrong file path");
    };
    parser.didFailWithError = ^(NSError *error) {
        STAssertNil(error, @"Unexpected error: %@", error);
    };
	
    [parser parse];
    [parser release];
}

@end
