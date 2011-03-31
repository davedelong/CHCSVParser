#import <Foundation/Foundation.h>
#import "CHCSV.h"

@interface Delegate : NSObject <CHCSVParserDelegate>
@end
@implementation Delegate

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
	NSLog(@"parser started: %@", csvFile);
}
- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber {
	NSLog(@"Starting line: %lu", lineNumber);
}
- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field {
	NSLog(@"   field: %@", field);
}
- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber {
	NSLog(@"Ending line: %lu", lineNumber);
}
- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {
	NSLog(@"parser ended: %@", csvFile);
}
- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
	NSLog(@"ERROR: %@", error);
}
@end



int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * file = @"/Users/dave/Developer/Open Source/Git Projects/CHCSVParser/test.tsv";
	NSStringEncoding encoding = 0;
	CHCSVParser * p = [[CHCSVParser alloc] initWithContentsOfCSVFile:file usedEncoding:&encoding error:nil];
	[p setDelimiter:@"\t"];
	
	NSLog(@"encoding: %@", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)));
	
	Delegate * d = [[Delegate alloc] init];
	[p setParserDelegate:d];
	
	[p parse];
	
	[d release];
	[p release];
	
	NSError * error = nil;
	NSArray * rows = [[NSArray alloc] initWithContentsOfCSVFile:file usedEncoding:&encoding delimiter:@"\t" error:&error];
	if ([rows count] == 0) {
		NSLog(@"error: %@", error);
		error = nil;
		rows = [NSArray arrayWithContentsOfCSVFile:file encoding:NSUTF8StringEncoding error:&error];
	}
	NSLog(@"error: %@", error);
	NSLog(@"%@", rows);
	
	CHCSVWriter *w = [[CHCSVWriter alloc] initWithCSVFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"test.tsv"] atomic:NO];
	[w setDelimiter:@"\t"];
	for (NSArray *row in rows) {
		[w writeLineWithFields:row];
	}
	[w closeFile];
	[w release];
    
	[rows release];
	[pool drain];
    return 0;
}
