//
//  CHCSVParser.h
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

#import <Foundation/Foundation.h>

@protocol CHCSVParserDelegate;

@interface CHCSVParser : NSObject {

	@private
	__weak id<CHCSVParserDelegate> parserDelegate;
    NSInputStream *csvReadStream;
	BOOL endOfStreamReached;
	NSStringEncoding fileEncoding;
    
	NSString *csvFile;
	
	BOOL hasStarted;
	NSString *delimiter;
	unichar delimiterCharacter;
	
	NSMutableData *currentChunk;
	NSMutableString *currentChunkString;
	NSUInteger chunkSize;
	NSUInteger stringIndex;
	
	BOOL balancedQuotes;
	BOOL balancedEscapes;
	
	NSMutableString *currentField;
	NSUInteger currentLine;
	
	NSUInteger state;
	NSError *error;
}

@property (weak) id<CHCSVParserDelegate> parserDelegate;
@property (readonly) NSError * error;
@property (readonly) NSString * csvFile;
@property (nonatomic, copy) NSString *delimiter;
@property (nonatomic) NSUInteger chunkSize;

- (id) initWithStream:(NSInputStream *)readStream usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)anError; //designated initializer
- (id) initWithStream:(NSInputStream *)readStream encoding:(NSStringEncoding)encoding error:(NSError **)anError;

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile encoding:(NSStringEncoding)encoding error:(NSError **)anError;
- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)anError;

- (id) initWithCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)anError;

- (void) parse;
- (void) cancelParsing;

@end

@protocol CHCSVParserDelegate <NSObject>

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile;
- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber;

- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber;

- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field;

- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile;

- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;

@end
