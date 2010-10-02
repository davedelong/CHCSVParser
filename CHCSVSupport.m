//
//  CHCSVSupport.m
//  CHCSVParser
//
//  Created by Dave DeLong on 10/2/10.
//  Copyright 2010 Home. All rights reserved.
//

#import "CHCSVSupport.h"


@implementation NSArrayCHCSVAggregator
@synthesize lines, error;

- (void) dealloc {
	[lines release];
	[currentLine release];
	[error release];
	[super dealloc];
}

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
	lines = [[NSMutableArray alloc] init];
}

- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber {
	currentLine = [[NSMutableArray alloc] init];
}

- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber {
	[lines addObject:currentLine];
	[currentLine release], currentLine = nil;
}

- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field {
	[currentLine addObject:field];
}

- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {
	
}

- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)anError {
	error = [anError retain];
}

@end