//
//  NSArray+CHCSVAdditions.m
//  CHCSVParser
//
//  Created by Dave DeLong on 7/31/10.
//  Copyright 2010 Home. All rights reserved.
//

#import "NSArray+CHCSVAdditions.h"
#import "CHCSVParser.h"

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
	
	NSFileHandle * outputFileHandle = nil;
	NSString * outputFile = csvFile;
	if (atomically) {
		//generate a random file name
		outputFile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%d-%@", arc4random(), [csvFile lastPathComponent]]];
	}
	
	ok = [[NSFileManager defaultManager] createFileAtPath:outputFile contents:nil attributes:nil];
	
	if (!ok) { return NO; }
	
	outputFileHandle = [[NSFileHandle fileHandleForWritingAtPath:outputFile] retain];
	
	if (outputFileHandle == nil) { return NO; }
	
	//any field with a comma, double quote, or newline character must be escaped
	NSMutableCharacterSet * escapableSet = [NSMutableCharacterSet newlineCharacterSet];
	[escapableSet addCharactersInString:@",\"\\"];
	NSString * fieldDelimiter = @",";
	NSString * lineDelimiter = @"\n";
	
	NSStringEncoding encoding = 0;
	
	for (NSArray * row in self) {
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		NSUInteger numberOfFieldsInRow = [row count];
		NSUInteger currentFieldIndex = 0;
		
		for (currentFieldIndex = 0; currentFieldIndex < numberOfFieldsInRow; ++currentFieldIndex) {
			NSMutableString * field = [[[row objectAtIndex:currentFieldIndex] description] mutableCopy];
			if (encoding == 0) {
				encoding = [field fastestEncoding];
			}
			
			//process this field:
			if ([field rangeOfCharacterFromSet:escapableSet].location != NSNotFound ||
				[field hasPrefix:@"#"]) {
				//there are bad characters!
				[field replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:NSLiteralSearch range:NSMakeRange(0, [field length])];
				[field replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [field length])];
				[field insertString:@"\"" atIndex:0];
				[field appendString:@"\""];
			}
			
			[outputFileHandle writeData:[field dataUsingEncoding:encoding]];
			
			if (currentFieldIndex != (numberOfFieldsInRow - 1)) {
				//if we're not at the last field, write a comma
				[outputFileHandle writeData:[fieldDelimiter dataUsingEncoding:encoding]];
			}
		}
		[outputFileHandle writeData:[lineDelimiter dataUsingEncoding:encoding]];
		
		[pool release];
	}
	
	[outputFileHandle closeFile];
	[outputFileHandle release];
	
	if (atomically) {
		[[NSFileManager defaultManager] removeItemAtPath:csvFile error:nil];
		NSError * error = nil;
		ok = [[NSFileManager defaultManager] moveItemAtPath:outputFile toPath:csvFile error:&error];
		if (error != nil) {
			ok = NO;
		}
	}
	
	return ok;
}

@end
