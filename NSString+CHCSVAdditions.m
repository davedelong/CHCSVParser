//
//  NSString+CHCSVAdditions.m
//  CHCSVParser
//
//  Created by Dave DeLong on 10/2/10.
//  Copyright 2010 Home. All rights reserved.
//

#import "NSString+CHCSVAdditions.h"
#import "CHCSVParser.h"
#import "CHCSVSupport.h"

@implementation NSString (CHCSVAdditions)

- (NSArray *) CSVComponents {
	
	CHCSVParser * parser = [[CHCSVParser alloc] initWithCSVString:self encoding:[self fastestEncoding] error:nil];
	NSArrayCHCSVAggregator * delegate = [[NSArrayCHCSVAggregator alloc] init];
	[parser setParserDelegate:delegate];
	[parser parse];
	[parser release];
	
	NSArray * results = nil;
	if ([parser error] == nil) {
		results = [[[delegate lines] retain] autorelease];
	}
	[delegate release];
	
	return results;
}

@end
