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
@synthesize encoding, delimiter;

- (id) initWithCSVFile:(NSString *)outputFile atomic:(BOOL)atomicWrite {
	if ((self = [super init])) {
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
		hasStarted = NO;
		
		[self setDelimiter:@","];
	}
	return self;
}

- (id) initForWritingToString {
    if ((self = [super init])) {
        atomically = NO;
        destinationFile = nil;
        handleFile = nil;
        encoding = 0;
        hasStarted = NO;
        [self setDelimiter:@","];
    }
    return self;
}

- (NSString *) stringValue {
    return [[stringValue copy] autorelease];
}

- (void) dealloc {
	[self closeFile];
	[destinationFile release];
	[delimiter release];
	[handleFile release];
	[outputHandle release];
	[illegalCharacters release];
    [stringValue release];
	[super dealloc];
}

- (NSError *) error {
	return error;
}

- (void) setDelimiter:(NSString *)newDelimiter {
	if (hasStarted) {
		[NSException raise:NSInvalidArgumentException format:@"You cannot set a delimiter after writing has started"];
		return;
	}
	
	// the delimiter cannot be
	BOOL shouldThrow = ([newDelimiter length] != 1);
    unichar delimiterCharacter = [newDelimiter characterAtIndex:0];
	if ([[NSCharacterSet newlineCharacterSet] characterIsMember:delimiterCharacter]) {
		shouldThrow = YES;
	}
	if (delimiterCharacter == '#') { shouldThrow = YES; }
	if (delimiterCharacter == '"') { shouldThrow = YES; }
	if (delimiterCharacter == '\\') { shouldThrow = YES; }
	
	if (shouldThrow) {
		[NSException raise:NSInvalidArgumentException format:@"%@ cannot be used as a delimiter", newDelimiter];
		return;
	}
	
	if (newDelimiter != delimiter) {
		[delimiter release];
		delimiter = [newDelimiter copy];
		
		[illegalCharacters release];
		NSMutableCharacterSet * bad = [NSMutableCharacterSet newlineCharacterSet];
		[bad addCharactersInString:@"\"\\"];
		[bad addCharactersInString:delimiter];
		illegalCharacters = [bad copy];
	}
}

- (void)_writeString:(NSString *)string {
	if (encoding == 0) {
		encoding = NSUTF8StringEncoding;
	}
    
    if (outputHandle != nil) {
        [outputHandle writeData:[string dataUsingEncoding:encoding]];
    } else {
        if (stringValue == nil) {
            stringValue = [[NSMutableString alloc] init];
        }
        [stringValue appendString:string];
    }
}

- (void) writeField:(id)field {
	hasStarted = YES;
	NSMutableString * write = [[field description] mutableCopy];
	
	if (currentField > 0) {
        [self _writeString:delimiter];
	}
	
	if ([write rangeOfCharacterFromSet:illegalCharacters].location != NSNotFound || [write hasPrefix:@"#"]) {
		[write replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:NSLiteralSearch range:NSMakeRange(0, [write length])];
		[write replaceOccurrencesOfString:@"\\" withString:@"\\\\" options:NSLiteralSearch range:NSMakeRange(0, [write length])];
		[write insertString:@"\"" atIndex:0];
		[write appendString:@"\""];
	}
	
    [self _writeString:write];
	[write release];
	currentField++;
}

- (void) writeFields:(id)field, ... {
	if (field == nil) { return; }
	
	[self writeField:field];
	
	va_list args;
	va_start(args, field);
	id next = nil;
	while ((next = va_arg(args, id))) {
		[self writeField:next];
	}
	va_end(args);
}

- (void) writeLine {
    [self _writeString:@"\n"];
	currentField = 0;
}

- (void) writeLineOfFields:(id)field, ... {
	if (field == nil) { return; }
	NSMutableArray *fields = [NSMutableArray arrayWithObject:field];
	va_list args;
	va_start(args, field);
	id next = nil;
	while ((next = va_arg(args, id))) {
		[fields addObject:next];
	}
	[self writeLineWithFields:fields];
	va_end(args);
}

- (void) writeLineWithFields:(NSArray *)fields {
	for (id field in fields) {
		[self writeField:field];
	}
	[self writeLine];
}

- (void) writeCommentLine:(id)comment {
	if (currentField > 0) { [self writeLine]; }
    [self _writeString:@"#"];
    [self _writeString:comment];
	[self writeLine];
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
