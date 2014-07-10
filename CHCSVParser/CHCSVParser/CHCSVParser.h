//
//  CHCSVParser.h
//  CHCSVParser
/**
 Copyright (c) 2012 Dave DeLong
 
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

extern NSString * const CHCSVErrorDomain;

typedef NS_ENUM(NSInteger, CHCSVErrorCode) {
    CHCSVErrorCodeInvalidFormat = 1,
    CHCSVErrorCodeIncorrectNumberOfFields,
};

@class CHCSVParser;
@protocol CHCSVParserDelegate <NSObject>

@optional
- (void)parserDidBeginDocument:(CHCSVParser *)parser;
- (void)parserDidEndDocument:(CHCSVParser *)parser;

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber;
- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber;

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex;
- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment;

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error;

@end

@interface CHCSVParser : NSObject

@property (assign) id<CHCSVParserDelegate> delegate;
@property (assign) BOOL recognizesBackslashesAsEscapes; // default is NO
@property (assign) BOOL sanitizesFields; // default is NO
@property (assign) BOOL recognizesComments; // default is NO
@property (assign) BOOL stripsLeadingAndTrailingWhitespace; // default is NO

@property (readonly) NSUInteger totalBytesRead;

- (id)initWithInputStream:(NSInputStream *)stream usedEncoding:(NSStringEncoding *)encoding delimiter:(unichar)delimiter NS_DESIGNATED_INITIALIZER;

- (id)initWithCSVString:(NSString *)csv;
- (id)initWithCSVString:(NSString *)csv delimiter:(unichar)delimiter;

- (id)initWithContentsOfCSVFile:(NSString *)csvFilePath;
- (id)initWithContentsOfCSVFile:(NSString *)csvFilePath delimiter:(unichar)delimiter;

- (void)parse;
- (void)cancelParsing;

@end

@interface CHCSVWriter : NSObject

- (instancetype)initForWritingToCSVFile:(NSString *)path;
- (instancetype)initWithOutputStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter NS_DESIGNATED_INITIALIZER;

- (void)writeField:(NSString *)field;
- (void)finishLine;

- (void)writeLineOfFields:(id<NSFastEnumeration>)fields;

- (void)writeComment:(NSString *)comment;

- (void)closeStream;

@end

#pragma mark - Convenience Categories

typedef NS_OPTIONS(NSUInteger, CHCSVParserOptions) {
    CHCSVParserOptionsRecognizesBackslashesAsEscapes = 1 << 0,
    CHCSVParserOptionsSanitizesFields = 1 << 1,
    CHCSVParserOptionsRecognizesComments = 1 << 2,
    CHCSVParserOptionsTrimsWhitespace = 1 << 3,
    
    // When you specify this option, instead of getting an Array of Arrays of Strings,
    // you get an Array of CHCSVOrderedDictionaries
    CHCSVParserOptionsUsesFirstLineAsKeys = 1 << 4
};

@interface CHCSVOrderedDictionary : NSDictionary

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (id)objectAtIndex:(NSUInteger)idx;

@end

@interface NSArray (CHCSVAdditions)

+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath;
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath delimiter:(unichar)delimiter;
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options;
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options delimiter:(unichar)delimiter;
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options delimiter:(unichar)delimiter error:(NSError *__autoreleasing *)error;
- (NSString *)CSVString;

@end

@interface NSString (CHCSVAdditions)

- (NSArray *)CSVComponents;
- (NSArray *)CSVComponentsWithDelimiter:(unichar)delimiter;
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options;
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options delimiter:(unichar)delimiter;
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options delimiter:(unichar)delimiter error:(NSError *__autoreleasing *)error;

@end
