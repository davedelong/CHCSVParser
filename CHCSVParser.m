//
//  CHCSVParser.m
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

#import "CHCSVParser.h"
#define CHUNK_SIZE 32
#define STRING_QUOTE @"\""
#define STRING_COMMA @","
#define STRING_BACKSLASH @"\\"

enum {
	CHCSVParserStateInsideFile = 0,
	CHCSVParserStateInsideLine = 1,
	CHCSVParserStateInsideField = 2,
	CHCSVParserStateInsideComment = 3,
    CHCSVParserStateCancelled = 4
};

@interface NSMutableString (CHCSVAdditions)

- (void) trimString_csv:(NSString *)character;
- (void) trimCharactersInSet_csv:(NSCharacterSet *)set;
- (void) replaceOccurrencesOfString:(NSString *)find withString_csv:(NSString *)replace;

@end

@implementation NSMutableString (CHCSVAdditions)

- (void) trimString_csv:(NSString *)character {
	[self replaceCharactersInRange:NSMakeRange(0, [character length]) withString:@""];
	[self replaceCharactersInRange:NSMakeRange([self length] - [character length], [character length]) withString:@""];
}

- (void) trimCharactersInSet_csv:(NSCharacterSet *)set {
	NSString * trimmed = [self stringByTrimmingCharactersInSet:set];
	[self setString:trimmed];
}

- (void) replaceOccurrencesOfString:(NSString *)find withString_csv:(NSString *)replace {
	[self replaceOccurrencesOfString:find withString:replace options:NSLiteralSearch range:NSMakeRange(0, [self length])];
}

@end

@interface CHCSVParser ()

@property (retain) NSMutableData * currentChunk;

- (NSStringEncoding) textEncodingForData:(NSData *)chunkToSniff offset:(NSUInteger *)offset;

- (NSString *) nextCharacter;
- (void) runParseLoop;
- (void) processComposedCharacter:(NSString *)currentCharacter previousCharacter:(NSString *)previousCharacter previousPreviousCharacter:(NSString *)previousPreviousCharacter;

- (void) beginCurrentLine;
- (void) beginCurrentField;
- (void) finishCurrentField;
- (void) finishCurrentLine;

@end

#define SETSTATE(_s) if (state != CHCSVParserStateCancelled) { state = _s; }

@implementation CHCSVParser
@synthesize parserDelegate, currentChunk, error, csvFile;

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile encoding:(NSStringEncoding)encoding error:(NSError **)anError {
    self = [super init];
	if (self) {
		csvFile = [aCSVFile copy];
		csvFileHandle = [[NSFileHandle fileHandleForReadingAtPath:csvFile] retain];
		if (csvFileHandle == nil) {
			if (anError) {
				*anError = [NSError errorWithDomain:@"com.davedelong.csv" code:0 userInfo:[NSDictionary dictionaryWithObject:@"Unable to open file for reading" forKey:NSLocalizedDescriptionKey]];
			}
			[self release];
			return nil;
		}
		fileEncoding = encoding;
		
		balancedQuotes = YES;
		balancedEscapes = YES;
		
		currentLine = 0;
		currentField = [[NSMutableString alloc] init];
		
		currentChunk = [[NSMutableData alloc] init];
		doneReadingFile = NO;
        currentChunkString = [[NSMutableString alloc] init];
		stringIndex = 0;
		
        SETSTATE(CHCSVParserStateInsideFile)
	}
	return self;
}

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)anError {
    self = [self initWithContentsOfCSVFile:aCSVFile encoding:NSUTF8StringEncoding error:anError];
	if (self) {
		
		NSData * chunk = [csvFileHandle readDataOfLength:CHUNK_SIZE];
		NSUInteger seekOffset = 0;
		fileEncoding = [self textEncodingForData:chunk offset:&seekOffset];
		[csvFileHandle seekToFileOffset:seekOffset];
		
		if (usedEncoding) {
			*usedEncoding = fileEncoding;
		}
	}
	return self;
}

- (id) initWithCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)anError {
    self = [super init];
	if (self) {
		csvFile = nil;
		csvFileHandle = nil;
		fileEncoding = encoding;
		
		balancedQuotes = YES;
		balancedEscapes = YES;
		
		currentLine = 0;
		currentField = [[NSMutableString alloc] init];
		
		currentChunkString = [csvString mutableCopy];
		doneReadingFile = YES;
		stringIndex = 0;
		
        SETSTATE(CHCSVParserStateInsideFile)
	}
	return self;
}

- (void) dealloc {
	[csvFileHandle release];
	[csvFile release];
	[currentField release];
	[currentChunk release];
	[currentChunkString release];
	[error release];
	
	[super dealloc];
}

- (NSStringEncoding) textEncodingForData:(NSData *)chunkToSniff offset:(NSUInteger *)offset {
	NSUInteger length = [chunkToSniff length];
	*offset = 0;
	NSStringEncoding encoding = NSUTF8StringEncoding;
	
	if (length > 0) {
		UInt8* bytes = (UInt8*)[chunkToSniff bytes];
		encoding = CFStringConvertEncodingToNSStringEncoding(CFStringGetSystemEncoding());
		switch (bytes[0]) {
			case 0x00:
				if (length>3 && bytes[1]==0x00 && bytes[2]==0xFE && bytes[3]==0xFF) {
					encoding = NSUTF32BigEndianStringEncoding;
					*offset = 4;
				}
				break;
			case 0xEF:
				if (length>2 && bytes[1]==0xBB && bytes[2]==0xBF) {
					encoding = NSUTF8StringEncoding;
					*offset = 3;
				}
				break;
			case 0xFE:
				if (length>1 && bytes[1]==0xFF) {
					encoding = NSUTF16BigEndianStringEncoding;
					*offset = 2;
				}
				break;
			case 0xFF:
				if (length>1 && bytes[1]==0xFE) {
					if (length>3 && bytes[2]==0x00 && bytes[3]==0x00) {
						encoding = NSUTF32LittleEndianStringEncoding;
						*offset = 4;
					} else {
						encoding = NSUTF16LittleEndianStringEncoding;
						*offset = 2;
					}
				}
				break;
			default:
				if ([[[NSString alloc] initWithData:chunkToSniff encoding:NSUTF8StringEncoding] autorelease] == nil) {
					NSLog(@"unable to determine file encoding; assuming MacOSRoman");
					encoding = NSMacOSRomanStringEncoding;
				} else {
					NSLog(@"unable to determine file encoding; assuming UTF8");
					encoding = NSUTF8StringEncoding; // fall back on UTF8
				}
				break;
		}
	}
	
	return encoding;
}

#pragma mark Parsing methods

- (void) readNextChunk {
    NSData * nextChunk = nil;
    @try {
        nextChunk = [csvFileHandle readDataOfLength:CHUNK_SIZE];
    }
    @catch (NSException * e) {
        error = [[NSError alloc] initWithDomain:@"com.davedelong.csv" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                       e, NSUnderlyingErrorKey,
                                                                                       [e reason], NSLocalizedDescriptionKey,
                                                                                       nil]];
        nextChunk = nil;
    }
    
    if ([nextChunk length] > 0) {
        // we were able to read something!
        [currentChunk appendData:nextChunk];
        
        NSUInteger readLength = [currentChunk length];
        do {
            NSString *readString = [[NSString alloc] initWithBytes:[currentChunk bytes] length:readLength encoding:fileEncoding];
            if (readString == nil) {
                readLength--;
                if (readLength == 0) {
                    error = [[NSError alloc] initWithDomain:@"com.davedelong.csv" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                   @"unable to interpret current chunk as a string", NSLocalizedDescriptionKey,
                                                                                                   nil]];
                    break;
                }
            } else {
                [currentChunkString appendString:readString];
                [readString release];
                break;
            }
        } while (1);
        
        
        [currentChunk replaceBytesInRange:NSMakeRange(0, readLength) withBytes:NULL length:0];
    }
    if ([nextChunk length] < CHUNK_SIZE) {
        doneReadingFile = YES;
    }
}

- (NSString *) nextCharacter {
	if (doneReadingFile == NO && stringIndex >= [currentChunkString length]/2) {
        [self readNextChunk];
	}
	
	if (stringIndex >= [currentChunkString length]) { return nil; }
	if ([currentChunkString length] == 0) { return nil; }
	
	NSRange charRange = [currentChunkString rangeOfComposedCharacterSequenceAtIndex:stringIndex];
	NSString * nextChar = [currentChunkString substringWithRange:charRange];
	stringIndex = charRange.location + charRange.length;
	return nextChar;
}

- (void) parse {
	[[self parserDelegate] parser:self didStartDocument:[self csvFile]];
	
	[self runParseLoop];
	
	if (error != nil) {
		[[self parserDelegate] parser:self didFailWithError:error];
	} else {
		[[self parserDelegate] parser:self didEndDocument:[self csvFile]];
	}
}

- (void) runParseLoop {
	NSString * currentCharacter = nil;
	NSString * previousCharacter = nil;
	NSString * previousPreviousCharacter = nil;
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	unsigned short counter = 0;
	
	while (error == nil && 
		   (currentCharacter = [self nextCharacter]) && 
		   currentCharacter != nil) {
		[self processComposedCharacter:currentCharacter previousCharacter:previousCharacter previousPreviousCharacter:previousPreviousCharacter];
        
        if (state == CHCSVParserStateCancelled) { break; }
        
		previousPreviousCharacter = previousCharacter;
		previousCharacter = currentCharacter;
		
		counter++;
		if (counter == 0) { //this happens every 65,536 (2**16) iterations when the unsigned short overflows
			[currentCharacter retain];
			[previousCharacter retain];
			[previousPreviousCharacter retain];
			
			[pool drain];
			pool = [[NSAutoreleasePool alloc] init];
			
			[currentCharacter autorelease];
			[previousCharacter autorelease];
			[previousPreviousCharacter autorelease];
		}
	}
	
	[pool drain];
	
	if ([currentField length] > 0 && state == CHCSVParserStateInsideField) {
		[self finishCurrentField];
	}
	if (state == CHCSVParserStateInsideLine) {
		[self finishCurrentLine];
	}
}

- (void) processComposedCharacter:(NSString *)currentCharacter previousCharacter:(NSString *)previousCharacter previousPreviousCharacter:(NSString *)previousPreviousCharacter {
	if (state == CHCSVParserStateInsideFile) {
		//this is the "beginning of the line" state
		//this is also where we determine if we should ignore this line (it's a comment)
		if ([currentCharacter isEqual:@"#"] == NO) {
			[self beginCurrentLine];
		} else {
            SETSTATE(CHCSVParserStateInsideComment)
		}
	}
	
	unichar currentUnichar = [currentCharacter characterAtIndex:0];
	unichar previousUnichar = [previousCharacter characterAtIndex:0];
	
	if ([currentCharacter isEqual:STRING_QUOTE]) {
		if (state == CHCSVParserStateInsideLine) {
			//beginning a quoted field
			[self beginCurrentField];
			balancedQuotes = NO;
		} else if (state == CHCSVParserStateInsideField) {
			if (balancedEscapes == NO) {
				balancedEscapes = YES;
			} else {
				balancedQuotes = !balancedQuotes;
			}
		}
	} else if ([currentCharacter isEqual:STRING_COMMA]) {
		if (state == CHCSVParserStateInsideLine) {
			[self beginCurrentField];
			[self finishCurrentField];
		} else if (state == CHCSVParserStateInsideField) {
			if (balancedEscapes == NO) {
				balancedEscapes = YES;
			} else if (balancedQuotes == YES) {
				[self finishCurrentField];
			}
		}
	} else if ([currentCharacter isEqual:STRING_BACKSLASH]) {
		if (state == CHCSVParserStateInsideField) {
			balancedEscapes = !balancedEscapes;
		} else if (state == CHCSVParserStateInsideLine) {
			[self beginCurrentField];
			balancedEscapes = NO;
		}
	} else if ([[NSCharacterSet newlineCharacterSet] characterIsMember:currentUnichar] && [[NSCharacterSet newlineCharacterSet] characterIsMember:previousUnichar] == NO) {
		if (balancedQuotes == YES && balancedEscapes == YES) {
			if (state != CHCSVParserStateInsideComment) {
				[self finishCurrentField];
				[self finishCurrentLine];
			} else {
                SETSTATE(CHCSVParserStateInsideFile)
			}
		}
	} else {
		if ([previousCharacter isEqual:STRING_QUOTE] && [previousPreviousCharacter isEqual:STRING_BACKSLASH] == NO && balancedQuotes == YES && balancedEscapes == YES) {
			NSString * reason = [NSString stringWithFormat:@"Invalid CSV format on line #%lu immediately after \"%@\"", currentLine, currentField];
			error = [[NSError alloc] initWithDomain:@"com.davedelong.csv" code:0 userInfo:[NSDictionary dictionaryWithObject:reason forKey:NSLocalizedDescriptionKey]];
			return;
		}
		if (state != CHCSVParserStateInsideComment) {
			if (state != CHCSVParserStateInsideField) {
				[self beginCurrentField];
			}
            SETSTATE(CHCSVParserStateInsideField)
			if (balancedEscapes == NO) {
				balancedEscapes = YES;
			}
		}
	}
	
	if (state != CHCSVParserStateInsideComment) {
		[currentField appendString:currentCharacter];
	}
}

- (void) beginCurrentLine {
	currentLine++;
	[[self parserDelegate] parser:self didStartLine:currentLine];
    SETSTATE(CHCSVParserStateInsideLine)
}

- (void) beginCurrentField {
	[currentField setString:@""];
	balancedQuotes = YES;
	balancedEscapes = YES;
    SETSTATE(CHCSVParserStateInsideField)
}

- (void) finishCurrentField {
	[currentField trimCharactersInSet_csv:[NSCharacterSet newlineCharacterSet]];
	if ([currentField hasPrefix:STRING_QUOTE] && [currentField hasSuffix:STRING_QUOTE]) {
		[currentField trimString_csv:STRING_QUOTE];
	}
	if ([currentField hasPrefix:STRING_COMMA]) {
		[currentField replaceCharactersInRange:NSMakeRange(0, [STRING_COMMA length]) withString:@""];
	}
	
	[currentField trimCharactersInSet_csv:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	[currentField replaceOccurrencesOfString:@"\"\"" withString_csv:STRING_QUOTE];
	
	//replace all occurrences of regex: \\(.) with $1 (but not by using a regex)
	NSRange nextSlash = [currentField rangeOfString:STRING_BACKSLASH options:NSLiteralSearch range:NSMakeRange(0, [currentField length])];
	while(nextSlash.location != NSNotFound) {
		[currentField replaceCharactersInRange:nextSlash withString:@""];
		
		NSRange nextSearchRange = NSMakeRange(nextSlash.location + nextSlash.length, 0);
		nextSearchRange.length = [currentField length] - nextSearchRange.location;
		nextSlash = [currentField rangeOfString:STRING_BACKSLASH options:NSLiteralSearch range:nextSearchRange];
	}
	
	NSString * field = [currentField copy];
	[[self parserDelegate] parser:self didReadField:field];
	[field release];
	
	[currentField setString:@""];
	
    SETSTATE(CHCSVParserStateInsideLine)
}

- (void) finishCurrentLine {
	[[self parserDelegate] parser:self didEndLine:currentLine];
    SETSTATE(CHCSVParserStateInsideFile)
}

#pragma Cancelling

- (void) cancelParsing {
    SETSTATE(CHCSVParserStateCancelled)
}

@end
