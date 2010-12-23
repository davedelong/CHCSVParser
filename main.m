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
	NSString * file = @"/Users/dave/Developer/Cocoa/CHCSVParser/Test.csv";
	NSStringEncoding encoding = 0;
	CHCSVParser * p = [[CHCSVParser alloc] initWithContentsOfCSVFile:file usedEncoding:&encoding error:nil];
	
	NSLog(@"encoding: %@", CFStringGetNameOfEncoding(CFStringConvertNSStringEncodingToEncoding(encoding)));
	
	Delegate * d = [[Delegate alloc] init];
	[p setParserDelegate:d];
	
	[p parse];
	
	[d release];
	[p release];
	
	NSArray * rows = [NSArray arrayWithContentsOfCSVFile:file usedEncoding:&encoding error:nil];
	NSLog(@"%@", rows);
    
	[pool drain];
    return 0;
}
