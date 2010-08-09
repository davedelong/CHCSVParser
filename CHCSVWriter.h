//
//  CHCSVWriter.h
//  CHCSVParser
//
//  Created by Dave DeLong on 8/9/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CHCSVWriter : NSObject {
	NSString * destinationFile;
	NSString * handleFile;
	NSFileHandle * outputHandle;
	BOOL atomically;
	
	NSUInteger currentField;
	NSStringEncoding encoding;
	
	NSCharacterSet * illegalCharacters;
	
	NSError * error;
}

- (id) initWithCSVFile:(NSString *)outputFile atomic:(BOOL)atomicWrite;
- (NSError *) error;

- (void) writeField:(id)field;
- (void) writeLine;

- (void) closeFile;

@end
