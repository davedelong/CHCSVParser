//
//  NSArray+CHCSVAdditions.m
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

#import "NSArray+CHCSVAdditions.h"
#import "CHCSVParser.h"
#import "CHCSVWriter.h"

@interface NSArrayCHCSVAggregator : NSObject <CHCSVParserDelegate> {
	NSMutableArray * lines;
	NSMutableArray * currentLine;
	NSError * error;
}

@property (readonly) NSArray * lines;
@property (readonly) NSError * error;

@end

@implementation NSArrayCHCSVAggregator
@synthesize lines, error;

- (void) dealloc {
	[lines release];
	[currentLine release];
	[error release];
	[super dealloc];
}

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
	lines = [[NSMutableArray alloc] init];
}

- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber {
	currentLine = [[NSMutableArray alloc] init];
}

- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber {
	[lines addObject:currentLine];
	[currentLine release], currentLine = nil;
}

- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field {
	[currentLine addObject:field];
}

- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {

}

- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)anError {
	error = [anError retain];
}

@end



@implementation NSArray (CHCSVAdditions)

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile encoding:encoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	CHCSVParser * parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:csvFile encoding:encoding error:error];
	if (error && *error) {
		[parser release];
		return [self init];
	}
	NSArrayCHCSVAggregator * delegate = [[NSArrayCHCSVAggregator alloc] init];
	[parser setParserDelegate:delegate];
	
	[parser parse];
	[parser release];
	
	NSArray * lines = [[[delegate lines] retain] autorelease];
	NSError * parserError = [[[delegate error] retain] autorelease];
	
	[delegate release];
	
	if (parserError) {
		if (error) {
			*error = parserError;
			return [self init];
		}
	}
	return [self initWithArray:lines];
}

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	CHCSVParser * parser = [[CHCSVParser alloc] initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding error:error];
	if (error && *error) {
		[parser release];
		return [self init];
	}
	NSArrayCHCSVAggregator * delegate = [[NSArrayCHCSVAggregator alloc] init];
	[parser setParserDelegate:delegate];
	
	[parser parse];
	
	NSArray * lines = [[[delegate lines] retain] autorelease];
	NSError * parserError = [[[delegate error] retain] autorelease];
	
	[delegate release];
	[parser release];
	
	if (parserError) {
		if (error) {
			*error = parserError;
			return [self init];
		}
	}
	return [self initWithArray:lines];
}

- (BOOL) writeToCSVFile:(NSString *)csvFile atomically:(BOOL)atomically {
	//first, verify that this is (at least) an NSArray of NSArrays:
	for (id object in self) {
		if ([object isKindOfClass:[NSArray class]] == NO) { return NO; }
	}
	
	BOOL ok = YES;
	
	CHCSVWriter * writer = [[CHCSVWriter alloc] initWithCSVFile:csvFile atomic:atomically];
	for (NSArray * row in self) {
		for (NSArray * field in row) {
			[writer writeField:field];
		}
		[writer writeLine];
	}
	
	ok = ([writer error] == nil);
	[writer release];
	
	return ok;
}

@end
