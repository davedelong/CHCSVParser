//
//  CHCSVParser.h
//  CHCSVParser
//
//  Created by Dave DeLong on 7/30/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CHCSVParserDelegate;

@interface CHCSVParser : NSObject {

	@private
	__weak id<CHCSVParserDelegate> parserDelegate;
	NSFileHandle * csvFileHandle;
	NSString * csvFile;
	NSString * currentChunk;
	NSStringEncoding fileEncoding;
	NSUInteger chunkIndex;
	
	BOOL balancedQuotes;
	BOOL balancedEscapes;
	
	NSMutableString * currentField;
	NSUInteger currentLine;
	
	NSUInteger state;
	NSError * error;
}

@property (assign) __weak id<CHCSVParserDelegate> parserDelegate;
@property (readonly) NSError * error;
@property (readonly) NSString * csvFile;

- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile encoding:(NSStringEncoding)encoding error:(NSError **)anError;
- (id) initWithContentsOfCSVFile:(NSString *)aCSVFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)anError;
- (void) parse;

@end

@protocol CHCSVParserDelegate <NSObject>

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile;
- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber;

- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber;

- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field;

- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile;

- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;

@end
