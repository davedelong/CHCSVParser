//
//  CHCSVParser.h
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/12.
//
//

#import <Foundation/Foundation.h>

@class CHCSVParser;
@protocol CHCSVParserDelegate <NSObject>

@optional
- (void)parserDidBeginDocument:(CHCSVParser *)parser;
- (void)parserDidEndDocument:(CHCSVParser *)parser;

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber;
- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field;

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;

@end

@interface CHCSVParser : NSObject

@property (assign) id<CHCSVParserDelegate> delegate;
@property (assign) BOOL recognizesBackslashesAsEscapes; // default is YES
@property (assign) BOOL sanitizesFields; // default is NO

// designated initializer
- (id)initWithInputStream:(NSInputStream *)stream usedEncoding:(NSStringEncoding *)encoding delimiter:(unichar)delimiter;

- (id)initWithCSVString:(NSString *)csv;
- (id)initWithContentsOfCSVFile:(NSString *)csvFilePath;

- (void)parse;
- (void)cancelParsing;

@end
