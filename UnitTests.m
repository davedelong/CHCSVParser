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

@implementation UnitTests

- (void) testCSV {
	NSString * file = [[NSBundle bundleForClass:[self class]] pathForResource:@"Test" ofType:@"csv"];
	
	NSStringEncoding encoding = 0;
	NSError * error = nil;
	NSArray * fields = [NSArray arrayWithContentsOfCSVFile:file usedEncoding:&encoding error:&error];
	
	STAssertTrue(encoding == NSUTF8StringEncoding, @"Wrong encoding; given %@ (%lu)", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)), encoding);
	STAssertNil(error, @"Unexpected error: %@", error);
	
	NSArray * expectedFields = [NSArray arrayWithObjects:
								[NSArray arrayWithObjects:@"This",@"is",@"a",@"simple",@"line",nil],
								[NSArray arrayWithObjects:@"This",@"is",@"a",@"quoted",@"line",nil],
								[NSArray arrayWithObjects:@"This",@"is",@"a",@"mixed",@"line",nil],
								[NSArray arrayWithObjects:@"This",@"has",@"a\nmultiline\nfield",nil],
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
	
	NSUInteger expectedCount = [expectedFields count];
	NSUInteger actualCount = [fields count];
	STAssertTrue(expectedCount == actualCount, @"incorrect number of lines parsed.  expected %lu, given %lu", expectedCount, actualCount);
	for (int i = 0; i < MIN(expectedCount, actualCount); ++i) {
		NSArray * actualLine = [fields objectAtIndex:i];
		NSArray * expectedLine = [expectedFields objectAtIndex:i];
		
		STAssertTrue([actualLine isEqualToArray:expectedLine], @"lines differ.  Expected %@, given %@", expectedLine, actualLine);
	}
	
	NSString * tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.csv"];
	NSLog(@"Writing to file: %@", tempFile);
	BOOL writtenToFile = [expectedFields writeToCSVFile:tempFile atomically:YES];
	
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

@end
