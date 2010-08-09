//
//  CHCSVWriter.m
//  CHCSVParser
//
//  Created by Dave DeLong on 8/9/10.
//  Copyright 2010 Home. All rights reserved.
//

#import "CHCSVWriter.h"


@implementation CHCSVWriter

- (id) initWithCSVFile:(NSString *)outputFile atomic:(BOOL)atomicWrite {
	if (self = [super init]) {
		atomically = atomicWrite;
		
		destinationFile = [outputFile retain];
		
		if (atomically) {
			handleFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%d-%@", arc4random(), [destinationFile lastPathComponent]]] retain];
		} else {
			handleFile = [destinationFile retain];
		}
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:handleFile]) {
			[[NSFileManager defaultManager] removeItemAtPath:handleFile error:nil];
		}
		
		[[NSFileManager defaultManager] createFileAtPath:handleFile contents:nil attributes:nil];
		outputHandle = [[NSFileHandle fileHandleForWritingAtPath:handleFile] retain];
		
		encoding = 0;
		
		NSMutableCharacterSet * bad = [NSMutableCharacterSet newlineCharacterSet];
		[bad addCharactersInString:@",\"\\"];
		illegalCharacters = [bad retain];
	}
	return self;
}

- (void) dealloc {
	[destinationFile release];
	[handleFile release];
	[outputHandle release];
	[illegalCharacters release];
	[super dealloc];
}

- (NSError *) error {
	return error;
}

- (void) writeField:(id)field {
	NSMutableString * write = [[field description] mutableCopy];
	if (encoding == 0) {
		encoding = [write fastestEncoding];
	}
	
	if (currentField > 0) {
		[outputHandle writeData:[@"," dataUsingEncoding:encoding]];
	}
	
	if ([write rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound || [write hasPrefix:@"#"]) {
		[write replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:NSLiteralSearch range:NSMakeRange(0, [write length])];
		[write replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [write length])];
		[write insertString:@"\"" atIndex:0];
		[write appendString:@"\""];
	}
	
	[outputHandle writeData:[write dataUsingEncoding:encoding]];
	[write release];
	currentField++;
}

- (void) writeLine {
	if (encoding == 0) {
		encoding = NSUTF8StringEncoding;
	}
	[outputHandle writeData:[@"\n" dataUsingEncoding:encoding]];
	currentField = 0;
}

- (void) closeFile {
	[outputHandle closeFile];
	[outputHandle release], outputHandle = nil;
	
	if (atomically == YES && [handleFile isEqual:destinationFile] == NO) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]) {
			NSError *err = nil;
			[[NSFileManager defaultManager] removeItemAtPath:destinationFile error:&err];
			if (err != nil) {
				error = [err retain];
				return;
			}
			[[NSFileManager defaultManager] moveItemAtPath:handleFile toPath:destinationFile error:&err];
			if (err != nil) {
				error = [err retain];
			}
		}
	}
}

@end
