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

@interface RecordEvent : DelegateEvent
+ (instancetype)recordEventWithNumber:(NSUInteger)aNumber;
@property(assign) NSUInteger recordNumber;
@end
@interface BeginRecordEvent : RecordEvent
@end
@interface EndRecordEvent : RecordEvent
@end

@interface FieldEvent : DelegateEvent
@property(assign) NSUInteger index;
@property(copy) NSString *field;
+ (instancetype)fieldEventWithIndex:(NSUInteger)anIndex field:(NSString *)aField;
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
	STAssertEqualObjects([logger nextEvent], [BeginRecordEvent recordEventWithNumber:1], nil);
	STAssertEqualObjects([logger nextEvent], [FieldEvent fieldEventWithIndex:0 field:@""], nil);
	STAssertEqualObjects([logger nextEvent], [EndRecordEvent recordEventWithNumber:1], nil);
	STAssertEqualObjects([logger nextEvent], [EndDocumentEvent event], nil);
	STAssertEquals([logger.events count], (NSUInteger)5, nil);
}

- (void)testOneField {
	ParserDelegate *logger = [[ParserDelegate alloc] init];
	CHCSVParser *parser = [[CHCSVParser alloc] initWithCSVString:@"field"];
	parser.delegate = logger;
	[parser parse];
	STAssertEqualObjects([logger nextEvent], [BeginDocumentEvent event], nil);
	STAssertEqualObjects([logger nextEvent], [BeginRecordEvent recordEventWithNumber:1], nil);
	STAssertEqualObjects([logger nextEvent], [FieldEvent fieldEventWithIndex:0 field:@"field"], nil);
	STAssertEqualObjects([logger nextEvent], [EndRecordEvent recordEventWithNumber:1], nil);
	STAssertEqualObjects([logger nextEvent], [EndDocumentEvent event], nil);
	STAssertEquals([logger.events count], (NSUInteger)5, nil);
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
	[_events addObject:[BeginRecordEvent recordEventWithNumber:recordNumber]];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
	[_events addObject:[EndRecordEvent recordEventWithNumber:recordNumber]];
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
	[_events addObject:[FieldEvent fieldEventWithIndex:fieldIndex field:field]];
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

@implementation RecordEvent
+ (instancetype)recordEventWithNumber:(NSUInteger)aNumber {
	RecordEvent *event = [self event];
	event.recordNumber = aNumber;
	return event;
}
- (BOOL)isEqual:(id)object {
	if (![super isEqual:object]) return NO;
	if (_recordNumber != ((RecordEvent *)object).recordNumber) return NO;
	return YES;
}
- (NSString *)description {
	return [NSString stringWithFormat:@"%@ recordNumber=%lu", [super description], _recordNumber];
}
@end

@implementation BeginRecordEvent
@end

@implementation EndRecordEvent
@end

@implementation FieldEvent

+ (instancetype)fieldEventWithIndex:(NSUInteger)anIndex field:(NSString *)aField {
	FieldEvent *event = [self event];
	event.index = anIndex;
	event.field = aField;
	return event;
}

- (BOOL)isEqual:(id)object {
	if (![super isEqual:object]) return NO;
	if (_index != ((FieldEvent *)object).index) return NO;
	if (![_field isEqual:((FieldEvent *)object).field]) return NO;
	return YES;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ index=%lu field='%@'", [super description], _index, _field];
}

@end