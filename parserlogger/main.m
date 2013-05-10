//
//  main.m
//  parserlogger
//
//  Created by Malte Tancred on 2013-05-10.
//
//

#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@interface ParserLogger : NSObject <CHCSVParserDelegate>
@end

int main(int argc, const char * argv[]) {
	if (argc < 2) {
		fprintf(stderr, "not enough arguments (%d)\n", argc);
		exit(1);
	}

	@autoreleasepool {
		ParserLogger *logger = [[ParserLogger alloc] init];
		CHCSVParser *parser = [[CHCSVParser alloc] initWithCSVString:[[NSProcessInfo processInfo] arguments][1]];
		parser.delegate = logger;
		[parser parse];
	}
    return 0;
}

@implementation ParserLogger

- (void)parserDidBeginDocument:(CHCSVParser *)parser {
	fprintf(stdout, "BEGIN DOCUMENT\n");
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
	fprintf(stdout, "END DOCUMENT\n");
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
	fprintf(stdout, "BEGIN LINE %lu\n", recordNumber);
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
	fprintf(stdout, "END LINE %lu\n", recordNumber);
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
	fprintf(stdout, "FIELD %lu: '%s'\n", fieldIndex, [field UTF8String]);
}

- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment {
	fprintf(stdout, "COMMENT: '%s'\n", [comment UTF8String]);
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
	fprintf(stdout, "COMMENT: '%s'\n", [[error localizedDescription] UTF8String]);
}

@end