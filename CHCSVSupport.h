//
//  CHCSVSupport.h
//  CHCSVParser
//
//  Created by Dave DeLong on 10/2/10.
//  Copyright 2010 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@interface NSArrayCHCSVAggregator : NSObject <CHCSVParserDelegate> {
	NSMutableArray * lines;
	NSMutableArray * currentLine;
	NSError * error;
}

@property (readonly) NSArray * lines;
@property (readonly) NSError * error;

@end