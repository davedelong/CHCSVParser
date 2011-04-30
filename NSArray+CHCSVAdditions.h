//
//  NSArray+CHCSVAdditions.h
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


@interface NSArray (CHCSVAdditions)

+ (id) arrayWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error;

+ (id) arrayWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error;
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error;
- (id) initWithContentsOfCSVStream:(NSInputStream *)csvStream usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter error:(NSError **)error;

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVFile:(NSString *)csvFile encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error;

+ (id) arrayWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error;
- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding error:(NSError **)error;
- (id) initWithContentsOfCSVFile:(NSString *)csvFile usedEncoding:(NSStringEncoding *)usedEncoding delimiter:(NSString *)delimiter error:(NSError **)error;

+ (id) arrayWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding error:(NSError **)error;
- (id) initWithContentsOfCSVString:(NSString *)csvString encoding:(NSStringEncoding)encoding delimiter:(NSString *)delimiter error:(NSError **)error;

- (BOOL) writeToCSVFile:(NSString *)csvFile atomically:(BOOL)atomically error:(NSError **)error;
- (BOOL) writeToCSVFile:(NSString *)csvFile withDelimiter:(NSString *)delimiter atomically:(BOOL)atomically error:(NSError **)error;

- (NSString *) CSVString;
- (NSString *) CSVStringWithDelimiter:(NSString *)delimiter error:(NSError **)error;

@end
