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
#define CHUNK_SIZE 1024
#define STRING_QUOTE @"\""
#define STRING_COMMA @","
#define STRING_BACKSLASH @"\\"

enum {
	CHCSVParserStateInsideFile = 0,
	CHCSVParserStateInsideLine = 1,
	CHCSVParserStateInsideField = 2,
	CHCSVParserStateInsideComment = 3
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

@property (retain) NSString * currentChunk;

- (NSStringEncoding) textEncodingForData:(NSData *)chunkToSniff offset:(NSUInteger *)offset;

- (NSString *) nextCharacter;
- (void) runParseLoop;
- (void) processComposedCharacter:(NSString *)currentCharacter previousCharacter:(NSString *)previousCharacter previousPreviousCharacter:(NSString *)previousPreviousCharacter;

- (void) beginCurrentLine;
- (void) beginCurrentField;
- (void) finishCurrentField;
- (void) finishCurrentLine;

@end



@implementation CHCSVParser
@synthesize parserDelegate, currentChunk, error, csvFile;

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile encoding:(NSStringEncoding)encoding error:(NSError **)anError {
	if (self = [super init]) {
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
		
		currentChunk = nil;
		chunkIndex = 0;
		
		state = CHCSVParserStateInsideFile;
	}
	return self;
}

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)anError {
	if (self = [self initWithContentsOfCSVFile:aCSVFile encoding:NSUTF8StringEncoding error:anError]) {
		
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
	if (self = [super init]) {
		csvFile = nil;
		csvFileHandle = nil;
		fileEncoding = encoding;
		
		balancedQuotes = YES;
		balancedEscapes = YES;
		
		currentLine = 0;
		currentField = [[NSMutableString alloc] init];
		
		currentChunk = [csvString copy];
		chunkIndex = 0;
		
		state = CHCSVParserStateInsideFile;
	}
	return self;
}

- (void) dealloc {
	[csvFileHandle release];
	[csvFile release];
	[currentField release];
	[currentChunk release];
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
				encoding = NSUTF8StringEncoding; // fall back on UTF8
				break;
		}
	}
	
	return encoding;
}

#pragma mark Parsing methods

- (NSString *) nextCharacter {
	if (chunkIndex >= [currentChunk length]) {
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
		
		if (nextChunk != nil) {
			NSString * chunkString = [[NSString alloc] initWithData:nextChunk encoding:fileEncoding];
			[self setCurrentChunk:chunkString];
			[chunkString release];
			chunkIndex = 0;
		} else {
			[self setCurrentChunk:nil];
		}
	}
	
	//return nil to indicate EOF or error
	if ([currentChunk length] == 0) { return nil; }
	
	NSRange charRange = [currentChunk rangeOfComposedCharacterSequenceAtIndex:chunkIndex];
	NSString * nextChar = [currentChunk substringWithRange:charRange];
	chunkIndex = charRange.location + charRange.length;
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
	
	while (error == nil && 
		   (currentCharacter = [self nextCharacter]) && 
		   currentCharacter != nil) {
		[self processComposedCharacter:currentCharacter previousCharacter:previousCharacter previousPreviousCharacter:previousPreviousCharacter];
		previousPreviousCharacter = previousCharacter;
		previousCharacter = currentCharacter;
	}
	
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
			state = CHCSVParserStateInsideComment;
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
				state = CHCSVParserStateInsideFile;
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
			state = CHCSVParserStateInsideField;
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
	state = CHCSVParserStateInsideLine;
}

- (void) beginCurrentField {
	[currentField setString:@""];
	balancedQuotes = YES;
	balancedEscapes = YES;
	state = CHCSVParserStateInsideField;
}

- (void) finishCurrentField {
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
	
	state = CHCSVParserStateInsideLine;
}

- (void) finishCurrentLine {
	[[self parserDelegate] parser:self didEndLine:currentLine];
	state = CHCSVParserStateInsideFile;
}

@end
