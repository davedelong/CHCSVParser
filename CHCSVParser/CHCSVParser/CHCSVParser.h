//
//  CHCSVParser.h
//  CHCSVParser
/**
 Copyright (c) 2014 Dave DeLong
 
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

#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif

#ifndef CHCSV_DEPRECATED
#define CHCSV_DEPRECATED(...) __attribute__((deprecated("" #__VA_ARGS__)))
#endif

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

// For a description of these properties, see the CHCSVParserOptions below
@property (nonatomic, assign) BOOL sanitizesFields; // default is NO
@property (nonatomic, assign) BOOL trimsWhitespace; // default is NO

@property (nonatomic, assign) BOOL recognizesBackslashesAsEscapes; // default is NO
@property (nonatomic, assign) BOOL recognizesComments; // default is NO
@property (nonatomic, assign) BOOL recognizesLeadingEqualSign; // default is NO

@property (nonatomic, assign) BOOL stripsLeadingAndTrailingWhitespace CHCSV_DEPRECATED(@"use .trimsWhitespace instead"); // default is NO

@property (readonly) NSUInteger totalBytesRead;

- (instancetype)initWithInputStream:(NSInputStream *)stream usedEncoding:(NSStringEncoding *)encoding delimiter:(unichar)delimiter NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCSVString:(NSString *)csv;
- (instancetype)initWithDelimitedString:(NSString *)string delimiter:(unichar)delimiter;

- (instancetype)initWithContentsOfCSVURL:(NSURL *)csvURL;
- (instancetype)initWithContentsOfDelimitedURL:(NSURL *)URL delimiter:(unichar)delimiter;

- (instancetype)initWithCSVString:(NSString *)csv delimiter:(unichar)delimiter CHCSV_DEPRECATED("use -initWithDelimitedString:delimiter: instead");
- (instancetype)initWithContentsOfCSVFile:(NSString *)csvFilePath CHCSV_DEPRECATED("use -initWithContentsOfCSVURL: instead");
- (instancetype)initWithContentsOfCSVFile:(NSString *)csvFilePath delimiter:(unichar)delimiter CHCSV_DEPRECATED("use -initWithContentsOfDelimitedURL:delimiter: instead");

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
    // Allows you to have delimiters and other control characters in a field without quoting the field
    // a,b\,c,d
    // If you use this option, you may not use "\" as the delimiter
    CHCSVParserOptionsRecognizesBackslashesAsEscapes = 1 << 0,
    
    // Cleans the field before reporting it (unescaping characters, stripping leading/trailing whitespace, etc)
    CHCSVParserOptionsSanitizesFields = 1 << 1,
    
    // Fields that begin with a "#" will be reported as comments. Comments are ended by unescaped newlines
    // If you use this option, you may not use "#" as the delimiter
    CHCSVParserOptionsRecognizesComments = 1 << 2,
    
    // Trims whitespace around a field
    CHCSVParserOptionsTrimsWhitespace = 1 << 3,
    
    // When you specify this option, instead of getting an Array of Arrays of Strings,
    // you get an Array of CHCSVOrderedDictionaries
    // If the CSV only contains a single line, then an empty array is returned
    CHCSVParserOptionsUsesFirstLineAsKeys = 1 << 4,
    
    // Some CSV files contain fields that look like:
    // a,="001234",b
    // http://edoceo.com/utilitas/csv-file-format
    // If you specify this option, you may not use "=" as the delimiter
    CHCSVParserOptionsRecognizesLeadingEqualSign = 1 << 5
};

@interface CHCSVOrderedDictionary : NSDictionary

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (id)objectAtIndex:(NSUInteger)idx;

@end

@interface NSArray (CHCSVAdditions)

+ (instancetype)arrayWithContentsOfCSVURL:(NSURL *)fileURL;
+ (instancetype)arrayWithContentsOfCSVURL:(NSURL *)fileURL options:(CHCSVParserOptions)options;
+ (instancetype)arrayWithContentsOfDelimitedURL:(NSURL *)fileURL delimiter:(unichar)delimiter;
+ (instancetype)arrayWithContentsOfDelimitedURL:(NSURL *)fileURL options:(CHCSVParserOptions)options delimiter:(unichar)delimiter;
+ (instancetype)arrayWithContentsOfDelimitedURL:(NSURL *)fileURL options:(CHCSVParserOptions)options delimiter:(unichar)delimiter error:(NSError *__autoreleasing *)error;

- (NSString *)CSVString;

// Deprecated methods

+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath CHCSV_DEPRECATED("Use +arrayWithContentsOfCSVURL: instead");
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath delimiter:(unichar)delimiter CHCSV_DEPRECATED("Use +arrayWithContentsOfDelimitedURL:delimiter: instead");
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options CHCSV_DEPRECATED("Use +arrayWithContentsOfCSVURL:options: instead");
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options delimiter:(unichar)delimiter CHCSV_DEPRECATED("Use +arrayWithContentsOfDelimitedURL:options:delimiter: instead");
+ (instancetype)arrayWithContentsOfCSVFile:(NSString *)csvFilePath options:(CHCSVParserOptions)options delimiter:(unichar)delimiter error:(NSError *__autoreleasing *)error CHCSV_DEPRECATED("Use +arrayWithContentsOfDelimitedURL:options:delimiter:error: instead");

@end

@interface NSString (CHCSVAdditions)

- (NSArray *)CSVComponents;
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options;
- (NSArray *)componentsSeparatedByDelimiter:(unichar)delimiter;
- (NSArray *)componentsSeparatedByDelimiter:(unichar)delimiter options:(CHCSVParserOptions)options;
- (NSArray *)componentsSeparatedByDelimiter:(unichar)delimiter options:(CHCSVParserOptions)options error:(NSError *__autoreleasing *)error;

// Deprecated methods

- (NSArray *)CSVComponentsWithDelimiter:(unichar)delimiter CHCSV_DEPRECATED("Use -componentsSeparatedByDelimiter: instead");
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options delimiter:(unichar)delimiter CHCSV_DEPRECATED("Use -componentsSeparatedByDelimiter:options: instead");
- (NSArray *)CSVComponentsWithOptions:(CHCSVParserOptions)options delimiter:(unichar)delimiter error:(NSError *__autoreleasing *)error CHCSV_DEPRECATED("Use -componentsSeparatedByDelimiter:options:error: instead");

@end
