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
#import "CHCSVSupport.h"

@implementation NSArray (CHCSVAdditions)

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile encoding:encoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [self initWithContentsOfCSVFile:csvFile encoding:encoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error {
	NSString * rawCSV = [NSString stringWithContentsOfFile:csvFile encoding:encoding error:error];
	if ((error && *error) || rawCSV == nil) {
		return [self init];
	}
	return [self initWithContentsOfCSVString:rawCSV encoding:encoding delimiter:delimiter error:error];
}

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	return [self initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter error:(NSError **)error {
	NSString * rawCSV = [NSString stringWithContentsOfFile:csvFile usedEncoding:usedEncoding error:error];
	if ((error && *error) || rawCSV == nil) {
		if (error) { *error = nil; }
		rawCSV = [NSString stringWithContentsOfFile:csvFile encoding:NSMacOSRomanStringEncoding error:error];
		if (usedEncoding) { *usedEncoding = NSMacOSRomanStringEncoding; }
	}
	if ((error && *error) || rawCSV == nil) {
		return [self init];
	}
	
	return [self initWithContentsOfCSVString:rawCSV encoding:(usedEncoding ? *usedEncoding : NSMacOSRomanStringEncoding) delimiter:delimiter error:error];
}

+ (id) arrayWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVString:csvString encoding:encoding error:error] autorelease];
}

- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [self initWithContentsOfCSVString:csvString encoding:encoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error {
	CHCSVParser * parser = [[CHCSVParser alloc] initWithCSVString:csvString encoding:encoding error:error];
	[parser setDelimiter:delimiter];
	
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

- (BOOL) writeToCSVFile:(NSString *)csvFile atomically:(BOOL)atomically error:(NSError **)error {
	return [self writeToCSVFile:csvFile withDelimiter:@"," atomically:atomically error:error];
}

- (BOOL) writeToCSVFile:(NSString *)csvFile withDelimiter:(NSString *)delimiter atomically:(BOOL)atomically error:(NSError **)error {
	//first, verify that this is (at least) an NSArray of NSArrays:
	for (id object in self) {
		if ([object isKindOfClass:[NSArray class]] == NO) { return NO; }
	}
	
	BOOL ok = YES;
	
	CHCSVWriter * writer = [[CHCSVWriter alloc] initWithCSVFile:csvFile atomic:atomically];
	[writer setDelimiter:delimiter];
	for (NSArray * row in self) {
		[writer writeLineWithFields:row];
	}
	
	ok = ([writer error] == nil);
	if (!ok && error) {
		*error = [[[writer error] retain] autorelease];
	}
	[writer closeFile];
	[writer release];
	
	return ok;
}

@end
