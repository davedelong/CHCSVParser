//
//  ParserTests.m
//  ParserTests
//
//  Created by Malte Tancred on 2013-05-09.
//
//

#import "ParserTests.h"
#import "CHCSVParser.h"

@interface DelegateEvent : NSObject
+ (instancetype)event;
@end

@interface ParserDelegate : NSObject <CHCSVParserDelegate>
@property(strong) NSMutableArray *events;
@property(assign) NSUInteger index;
- (DelegateEvent *)nextEvent;
@end

@interface BeginDocumentEvent : DelegateEvent
@end
@interface EndDocumentEvent : DelegateEvent
@end

@implementation ParserTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEmpty {
	ParserDelegate *logger = [[ParserDelegate alloc] init];
	CHCSVParser *parser = [[CHCSVParser alloc] initWithCSVString:@""];
	parser.delegate = logger;
	[parser parse];
	STAssertEqualObjects([logger nextEvent], [BeginDocumentEvent event], nil);
	STAssertEqualObjects([logger nextEvent], [EndDocumentEvent event], nil);
	STAssertEquals([logger.events count], (NSUInteger)2, nil);
}

@end


@implementation ParserDelegate

- (id)init {
	if (!(self = [super init])) return nil;
	self.events = [[NSMutableArray alloc] init];
	self.index = 0;
	return self;
}

- (DelegateEvent *)nextEvent {
	if (_index >= [_events count]) return nil;
	return _events[_index++];
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser {
	[_events addObject:[BeginDocumentEvent event]];
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
	[_events addObject:[EndDocumentEvent event]];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
}

- (void)parser:(CHCSVParser *)parser didReadComment:(NSString *)comment {
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
}

@end


@implementation DelegateEvent
+ (instancetype)event {
	return [[[self class] alloc] init];
}

- (BOOL)isEqual:(id)object {
	if (!object) return NO;
	return [[self class] isEqual:[object class]];
}

@end

@implementation BeginDocumentEvent
@end

@implementation EndDocumentEvent
@end
