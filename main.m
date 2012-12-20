#import <Foundation/Foundation.h>
#import "CHCSVParser.h"

@interface Delegate : NSObject <CHCSVParserDelegate>
@end
@implementation Delegate

- (void) parser:(CHCSVParser *)parser didStartDocument:(NSString *)csvFile {
//	NSLog(@"parser started: %@", csvFile);
}
- (void) parser:(CHCSVParser *)parser didStartLine:(NSUInteger)lineNumber {
//	NSLog(@"Starting line: %lu", lineNumber);
}
- (void) parser:(CHCSVParser *)parser didReadField:(NSString *)field {
//	NSLog(@"   field: %@", field);
}
- (void) parser:(CHCSVParser *)parser didEndLine:(NSUInteger)lineNumber {
//	NSLog(@"Ending line: %lu", lineNumber);
}
- (void) parser:(CHCSVParser *)parser didEndDocument:(NSString *)csvFile {
//	NSLog(@"parser ended: %@", csvFile);
}
- (void) parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
	NSLog(@"ERROR: %@", error);
}
@end



int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSString * file = @"/Users/dave/Developer/Open Source/Git Projects/CHCSVParser/Test.csv";
    file = @"/Users/dave/Downloads/test.csv";
    NSArray *a = [NSArray arrayWithContentsOfCSVFile:file];
    NSLog(@"%@", a);
    CHCSVParser *newP = [[CHCSVParser alloc] initWithContentsOfCSVFile:file];
//    [newP setRecognizesBackslashesAsEscapes:NO];
    [newP setSanitizesFields:YES];
    [newP parse];
    [newP release];
    
	/**
	CHCSVWriter *big = [[CHCSVWriter alloc] initWithCSVFile:file atomic:NO];
	for (int i = 0; i < 1000000; ++i) {
		NSAutoreleasePool *inner = [[NSAutoreleasePool alloc] init];
		for (int j = 0; j < 10; ++j) {
			[big writeField:[NSString stringWithFormat:@"%d-%d", i, j]];
		}
		[big writeLine];
		[inner drain];
	}
	[big closeFile];
	[big release];
	**/
	
	/**
	
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
	 **/
	
	NSLog(@"Beginning...");
	NSStringEncoding encoding = 0;
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:file];
	CHCSVParser * p = [[CHCSVParser alloc] initWithInputStream:stream usedEncoding:&encoding delimiter:','];
	
	NSLog(@"encoding: %@", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)));
	
	Delegate * d = [[Delegate alloc] init];
	[p setDelegate:d];
	
	NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
	[p parse];
	NSTimeInterval end = [NSDate timeIntervalSinceReferenceDate];
	
	NSLog(@"raw difference: %f", (end-start));
	
	[d release];
    
    
    a = [NSArray arrayWithContentsOfCSVFile:file];
    NSLog(@"%@", a);
    NSString *s = [a CSVString];
    NSLog(@"%@", s);
    
	[p release];
	
	[pool drain];
    return 0;
}
