//
//  CHCSVWriter.m
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

#import "CHCSVWriter.h"


@implementation CHCSVWriter
@synthesize encoding;

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
	[self closeFile];
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
	if (outputHandle) {
		[outputHandle closeFile];
		[outputHandle release], outputHandle = nil;
		
		if (atomically == YES && [handleFile isEqual:destinationFile] == NO) {
			NSError *err = nil;
			if ([[NSFileManager defaultManager] fileExistsAtPath:destinationFile]) {
				[[NSFileManager defaultManager] removeItemAtPath:destinationFile error:&err];
				if (err != nil) {
					error = [err retain];
					return;
				}
			}
			[[NSFileManager defaultManager] moveItemAtPath:handleFile toPath:destinationFile error:&err];
			if (err != nil) {
				error = [err retain];
			}
			[[NSFileManager defaultManager] removeItemAtPath:handleFile error:nil];
		}
	}
}

@end
