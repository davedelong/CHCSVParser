//
//  CHCSVWriter.h
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


@interface CHCSVWriter : NSObject {
	NSString * destinationFile;
	NSString * handleFile;
	NSFileHandle * outputHandle;
	BOOL atomically;
    NSMutableString *stringValue;
	BOOL hasStarted;
	
	NSUInteger currentField;
	NSStringEncoding encoding;
	NSString *delimiter;
	
	NSCharacterSet * illegalCharacters;
	
	NSError * error;
}

@property (nonatomic) NSStringEncoding encoding; //defaults to NSUTF8StringEncoding
@property (nonatomic, copy) NSString *delimiter; //defaults to ,

- (id) initWithCSVFile:(NSString *)outputFile atomic:(BOOL)atomicWrite;

- (id) initForWritingToString;
- (NSString *) stringValue;

- (NSError *) error;

- (void) writeField:(id)field;
- (void) writeFields:(id)field, ... NS_REQUIRES_NIL_TERMINATION;

- (void) writeLine;
- (void) writeLineOfFields:(id)field, ... NS_REQUIRES_NIL_TERMINATION;
- (void) writeLineWithFields:(NSArray *)fields;

- (void) writeCommentLine:(id)comment;

- (void) closeFile;

@end
