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

#import "CHCSV.h"

#pragma mark Support

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
	if ([currentLine count] > 0) {
		[lines addObject:currentLine];
	}
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

#pragma mark NSArray Category

@implementation NSArray (CHCSVAdditions)

+ (id) arrayWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding error:(NSError **)error {
    return [[[self alloc] initWithContentsOfCSVStream:csvStream encoding:encoding error:error] autorelease];
}
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream encoding:encoding delimiter:@"," error:error];
}
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:&encoding delimiter:delimiter error:error];
}
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:&encoding delimiter:delimiter lineDelimiter: lineDelimiter error:error];
}

+ (id) arrayWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
    return [[[self alloc] initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding error:error] autorelease];
}
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding delimiter:delimiter lineDelimiter: [NSCharacterSet newlineCharacterSet] error: error];
}

- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter error:(NSError **)error {
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding delimiter:delimiter lineDelimiter: lineDelimiter shouldParseBackSlashes: YES error: error];
}

- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter shouldParseBackSlashes:(BOOL)shouldParseBackSlashes error:(NSError **)error {
    //THIS IS THE "DESIGNATED" INITIALIZER
    //all other CSV initializers run through this one
    
    CHCSVParser *parser = [[CHCSVParser alloc] initWithStream:csvStream usedEncoding:usedEncoding error:error];
    parser.shouldParseBackSlashes = shouldParseBackSlashes;
	[parser setDelimiter:delimiter];
	[parser setLineDelimiter:lineDelimiter];
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
		}
		[self release];
		return nil;
	}
	return [self initWithArray:lines];
}

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile encoding:encoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [self initWithContentsOfCSVFile:csvFile encoding:encoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error {
    return [self initWithContentsOfCSVFile:csvFile encoding:encoding delimiter:delimiter lineDelimiter: [NSCharacterSet newlineCharacterSet] error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter error:(NSError **)error {
    NSInputStream *csvStream = [NSInputStream inputStreamWithFileAtPath:csvFile];
    return [self initWithContentsOfCSVStream:csvStream encoding:encoding delimiter:delimiter lineDelimiter: lineDelimiter error:error];
}

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding error:error] autorelease];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error {
	return [self initWithContentsOfCSVFile:csvFile usedEncoding:usedEncoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter error:(NSError **)error {
    NSInputStream *csvStream = [NSInputStream inputStreamWithFileAtPath:csvFile];
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding delimiter:delimiter error:error];
}

- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter error:(NSError **)error {
    NSInputStream *csvStream = [NSInputStream inputStreamWithFileAtPath:csvFile];
    return [self initWithContentsOfCSVStream:csvStream usedEncoding:usedEncoding delimiter:delimiter lineDelimiter: lineDelimiter error:error];
}

+ (id) arrayWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [[[self alloc] initWithContentsOfCSVString:csvString encoding:encoding error:error] autorelease];
}

- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error {
	return [self initWithContentsOfCSVString:csvString encoding:encoding delimiter:@"," error:error];
}

- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error {
	return [self initWithContentsOfCSVString:csvString encoding:encoding delimiter:delimiter lineDelimiter:[NSCharacterSet newlineCharacterSet] error:error];
}

- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter lineDelimiter: (NSString *)lineDelimiter error:(NSError **)error {
    NSInputStream *csvStream = [NSInputStream inputStreamWithData:[csvString dataUsingEncoding:encoding]];
    return [self initWithContentsOfCSVStream:csvStream encoding:encoding delimiter:delimiter lineDelimiter: lineDelimiter error:error];
}

- (BOOL) writeToCSVFile:(NSString *)csvFile atomically:(BOOL)atomically error:(NSError **)error {
	return [self writeToCSVFile:csvFile withDelimiter:@"," atomically:atomically error:error];
}

- (BOOL) writeToCSVFile:(NSString *)csvFile withDelimiter:(NSString *)delimiter atomically:(BOOL)atomically error:(NSError **)error {
	//first, verify that this is (at least) an NSArray of NSArrays:
	for (id object in self) {
		if ([object isKindOfClass:[NSArray class]] == NO) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:CHCSVErrorDomain code:CHCSVErrorCodeInvalidFormat userInfo:[NSDictionary dictionaryWithObject:@"Invalid array structure" forKey:NSLocalizedDescriptionKey]];
            }
            return NO;
        }
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

- (NSString *) CSVString {
    NSError *error = nil;
    return [self CSVStringWithDelimiter:@"," error:&error];
}

- (NSString *) CSVStringWithDelimiter:(NSString *)delimiter error:(NSError **)error {
    CHCSVWriter *writer = [[CHCSVWriter alloc] initForWritingToString];
    [writer setDelimiter:delimiter];
    for (NSArray *array in self) {
        [writer writeLineWithFields:array];
    }
    NSString *string = [writer stringValue];
    if (!string && error) {
        *error = [[[writer error] retain] autorelease];
    }
    [writer release];
    return string;
}

@end
