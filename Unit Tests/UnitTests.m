//
//  UnitTests.m
//  CHCSVParser
/**
 Copyright (c) 2014 Dave DeLong
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 **/

#import "UnitTests.h"
#import "UnitTestContent.h"
#import "CHCSVParser.h"

#define TEST_ARRAYS(_actual, _expected) do {\
XCTAssertEqual(_actual.count, _expected.count, @"incorrect number of records"); \
if (_actual.count == _expected.count) { \
for (NSUInteger _record = 0; _record < _actual.count; ++_record) { \
NSArray *_actualRow = _actual[_record]; \
NSArray *_expectedRow = _expected[_record]; \
XCTAssertEqual(_actualRow.count, _expectedRow.count, @"incorrect number of fields on line %lu", _record + 1); \
if (_actualRow.count == _expectedRow.count) { \
for (NSUInteger _field = 0; _field < _actualRow.count; ++_field) { \
id _actualField = _actualRow[_field]; \
id _expectedField = _expectedRow[_field]; \
XCTAssertEqualObjects(_actualField, _expectedField, @"mismatched field #%lu on line %lu", _field, _record + 1); \
if ([_actualField isEqual:_expectedField] == NO) { \
NSLog(@"expected data: %@", [_expectedField dataUsingEncoding:NSUTF8StringEncoding]); \
NSLog(@"actual data:   %@", [_actualField dataUsingEncoding:NSUTF8StringEncoding]); \
} \
} \
} \
} \
} \
} while(0)

#define TEST(_csv, _expected, ...) do {\
NSUInteger _optionList[] = {0, ##__VA_ARGS__}; \
NSUInteger _option = _optionList[(sizeof(_optionList)/sizeof(NSUInteger)) == 2 ? 1 : 0]; \
NSArray *_parsed = [(_csv) CSVComponentsWithOptions:(_option)]; \
TEST_ARRAYS(_parsed, _expected); \
} while(0)

@implementation UnitTests

- (NSURL *)temporaryURLForDelimitedString:(NSString *)string {
    static NSURL *temporaryFolder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *tmp = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        tmp = [tmp URLByAppendingPathComponent:@"CHCSVParser" isDirectory:YES];
        
        NSDateFormatter *f = [[NSDateFormatter alloc] init];
        f.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        f.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        f.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        f.dateFormat = @"yyyy.MM.dd.HH.mm.ss.SSSSS";
        
        NSString *folderName = [f stringFromDate:[NSDate date]];
        temporaryFolder = [tmp URLByAppendingPathComponent:folderName isDirectory:YES];
        XCTAssertNotNil(temporaryFolder, @"Unable to locate temporary directory");
        
        NSError *error = nil;
        BOOL created = [[NSFileManager defaultManager] createDirectoryAtURL:temporaryFolder withIntermediateDirectories:YES attributes:nil error:&error];
        
        XCTAssertTrue(created, @"Unable to create temporary directory (%@)", error);
        
        NSLog(@"Writing files to %@", temporaryFolder);
    });
    NSString *name = [NSUUID UUID].UUIDString;
    NSURL *url = [temporaryFolder URLByAppendingPathComponent:name];
    
    NSError *error = nil;
    BOOL written = [string writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
    XCTAssertTrue(written, @"Unable to write string to temporary folder: %@", error);
    
    return url;
}

- (void)testAvailableEncodings {
    const CFStringEncoding *encodings = CFStringGetListOfAvailableEncodings();
    
    while (*encodings != kCFStringEncodingInvalidId) {
        CFStringEncoding encoding = *encodings;
        NSStringEncoding nsEncoding = CFStringConvertEncodingToNSStringEncoding(encoding);
        if (nsEncoding == kCFStringEncodingInvalidId) {
            NSLog(@"Invalid: %@", CFStringGetNameOfEncoding(encoding));
        } else {
            NSData *a = [@"a" dataUsingEncoding:nsEncoding];
            NSData *aa = [@"aa" dataUsingEncoding:nsEncoding];
            NSData *bom = nil;
            if ([a length] * 2 != [aa length]) {
                NSUInteger characterLength = [aa length] - [a length];
                bom = [a subdataWithRange:NSMakeRange(0, [a length] - characterLength)];
            }
            
            NSLog(@"%@: %@", CFStringGetNameOfEncoding(encoding), bom);
        }
        
        
        encodings++;
    }
}

- (void)testSimple {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleUTF8 {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3, UTF8FIELD4], @[FIELD1, FIELD2, FIELD3, UTF8FIELD4]];
    TEST(csv, expected);
}

- (void)testDelimiterSniffing {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA UTF8FIELD4;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3, UTF8FIELD4], @[FIELD1, FIELD2, FIELD3, UTF8FIELD4]];
    TEST(csv, expected);
    csv = FIELD1 SEMICOLON FIELD2 SEMICOLON FIELD3 SEMICOLON UTF8FIELD4 NEWLINE FIELD1 SEMICOLON FIELD2 SEMICOLON FIELD3 SEMICOLON UTF8FIELD4;
    TEST(csv, expected);
    csv = FIELD1 TAB FIELD2 TAB FIELD3 TAB UTF8FIELD4 NEWLINE FIELD1 TAB FIELD2 TAB FIELD3 TAB UTF8FIELD4;
    TEST(csv, expected);
}

- (void)testGithubIssue35 {
    NSString *tsv = @"1,a" TAB @"1,b" TAB @"1,c" TAB @"1,\"d\"" NEWLINE
    @"2,a" TAB @"2,b" TAB @"2,c" TAB @"2,d" NEWLINE
    @"3,a" TAB @"3,b" TAB @"3,c" TAB @"3,d" NEWLINE
    @"4,a" TAB @"4,b" TAB @"4,c" TAB @"4,d" NEWLINE
    @"5,a" TAB @"5,b" TAB @"5,c" TAB @"5,d" NEWLINE
    @"6,a" TAB @"6,b" TAB @"6,c" TAB @"6,d" NEWLINE
    @"7,a" TAB @"7,b" TAB @"7,c" TAB @"7,d" NEWLINE
    @"8,a" TAB @"8,b" TAB @"8,c" TAB @"8,d" NEWLINE
    @"9,a" TAB @"9,b" TAB @"9,c" TAB @"9,d" NEWLINE
    @"10,a" TAB @"10,b" TAB @"10,c" TAB @"10,d";
    
    NSArray *expected = @[@[@"1,a", @"1,b", @"1,c", @"1,\"d\""],
                          @[@"2,a", @"2,b", @"2,c", @"2,d"],
                          @[@"3,a", @"3,b", @"3,c", @"3,d"],
                          @[@"4,a", @"4,b", @"4,c", @"4,d"],
                          @[@"5,a", @"5,b", @"5,c", @"5,d"],
                          @[@"6,a", @"6,b", @"6,c", @"6,d"],
                          @[@"7,a", @"7,b", @"7,c", @"7,d"],
                          @[@"8,a", @"8,b", @"8,c", @"8,d"],
                          @[@"9,a", @"9,b", @"9,c", @"9,d"],
                          @[@"10,a", @"10,b", @"10,c", @"10,d"]];
    
    NSArray *actual = [tsv componentsSeparatedByDelimiter:'\t'];
    TEST_ARRAYS(actual, expected);
}

- (void)testGithubIssue38 {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE OCTOTHORPE;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesComments);
}

- (void)testGithubIssue50 {
    NSString *csv = @"TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id";
    NSArray *expected = @[@[@"TRẦN",@"species_code",@"Scientific name",@"Author name",@"Common name",@"Family",@"Description",@"Habitat",@"\"Leaf size min (cm, 0 decimal digit)\"",@"\"Leaf size max (cm, 0 decimal digit)\"",@"Distribution",@"Current National Conservation Status",@"Growth requirements",@"Horticultural features",@"Uses",@"Associated fauna",@"Reference",@"species_id"]];
    TEST(csv, expected);
}

- (void)testGithubIssue50Workaround {
    NSString *csv = @"TRẦN,species_code,Scientific name,Author name,Common name,Family,Description,Habitat,\"Leaf size min (cm, 0 decimal digit)\",\"Leaf size max (cm, 0 decimal digit)\",Distribution,Current National Conservation Status,Growth requirements,Horticultural features,Uses,Associated fauna,Reference,species_id";
    
    NSURL *url = [self temporaryURLForDelimitedString:csv];
    NSArray *actual = [NSArray arrayWithContentsOfCSVURL:url];
    
    NSArray *expected = @[@[@"TRẦN",@"species_code",@"Scientific name",@"Author name",@"Common name",@"Family",@"Description",@"Habitat",@"\"Leaf size min (cm, 0 decimal digit)\"",@"\"Leaf size max (cm, 0 decimal digit)\"",@"Distribution",@"Current National Conservation Status",@"Growth requirements",@"Horticultural features",@"Uses",@"Associated fauna",@"Reference",@"species_id"]];
    XCTAssertEqualObjects(actual, expected, @"failed");
}

- (void)testGithubIssue53 {
    NSString *csv = @"F1,F2,F3" NEWLINE @"a, \"b, B\",c" NEWLINE @"A,B,C" NEWLINE @"1,2,3" NEWLINE @"I,II,III";
    NSArray *expected = @[@[@"F1",@"F2",@"F3"], @[@"a", @" \"b, B\"", @"c"], @[@"A", @"B", @"C"], @[@"1", @"2", @"3"], @[@"I", @"II", @"III"]];
    TEST(csv, expected);
}

- (void)testGithubIssue64 {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *fileURL = [bundle URLForResource:@"Issue64" withExtension:@"csv"];
    
    NSArray *actual = [NSArray arrayWithContentsOfCSVURL:fileURL];
    NSArray *expected = @[@[@"SplashID vID File -v2.0"],
                          @[@"F"],
                          @[@"T",@"21",@"Web Logins",@"Description",@"Username",@"Password",@"URL",@"Field 5",@"4",@""],
                          @[@"F",@"21",@"test",@"me",@"23123123",@"www.ya.ru",@"",@"",@"4",@"",@"",@"",@"",@"",@"",@"Personal",@"\"aasdasd\r\radasdasd\""],
                          @[@"T",@"3",@"Credit Cards",@"Description",@"Card #",@"Expiry Date",@"Name",@"PIN",@"18",@""],
                          @[@"F",@"3",@"карта",@"123123123213",@"23/23",@"Лдлоло Лдлодло",@"23223",@"",@"18",@"",@"",@"",@"",@"",@"",@"Unfiled",@"\"фывфывыфв\r\r\rфывфыв\""],
                          @[@"T",@"21",@"Web Logins",@"Description",@"Username",@"Password",@"URL",@"Field 5",@"4",@""],
                          @[@"F",@"21",@"test 2",@"me",@"23123123",@"www.ya.ru",@"f5",@"f6",@"4",@"",@"",@"",@"",@"",@"",@"Personal",@"\"aasdasd\r\radasdasd\""],
                          @[@"T",@"3",@"Credit Cards",@"Description",@"Card #",@"Expiry Date",@"Name",@"PIN",@"18",@""],
                          @[@"F",@"3",@"карта 2",@"123123123213",@"23/23",@"Лдлоло Лдлодло",@"23223",@"",@"18",@"",@"",@"",@"",@"",@"",@"Unfiled",@"\"фывфывыфв\r\r\rфывфыв\""]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testGithubIssue65 {
//    NSString *csv = FIELD1 @"æ" COMMA FIELD2 @"ø" COMMA FIELD3 @"å";
//    NSArray *expected = @[@[FIELD1 @"æ", FIELD2 @"ø", FIELD3 @"å"]];
//    TEST(csv, expected);
//    
//    NSArray *csvComponents = [csv CSVComponents];
//    TEST_ARRAYS(csvComponents, expected);
//    
//    csv = @"148" COMMA @"S†TTERLIN Jasha" COMMA @"MOV" COMMA @"MOVISTAR TEAM";
//    expected = @[@[@"148", @"S†TTERLIN Jasha", @"MOV", @"MOVISTAR TEAM"]];
//    TEST(csv, expected);
//    
//    csv = @"148" COMMA @"SÜTTERLIN Jasha" COMMA @"MOV" COMMA @"MOVISTAR TEAM";
//    expected = @[@[@"148", @"SÜTTERLIN Jasha", @"MOV", @"MOVISTAR TEAM"]];
//    TEST(csv, expected);
    
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *fileURL = [bundle URLForResource:@"Issue65" withExtension:@"csv"];
    
    NSArray *actual = [NSArray arrayWithContentsOfCSVURL:fileURL];
    NSArray *expected = @[@[@"Bib", @"Name", @"Teamcode", @"Team"],
                 @[@"71", @"DUMOULIN Tom", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"41", @"CANCELLARA Fabian", @"TFR", @"TREK FACTORY RACING"],
                 @[@"68", @"THOMAS Geraint", @"SKY", @"TEAM SKY"],
                 @[@"37", @"QUINZIATO Manuel", @"BMC", @"BMC RACING TEAM"],
                 @[@"46", @"SERGENT Jesse", @"TFR", @"TREK FACTORY RACING"],
                 @[@"39", @"CUMMINGS Stephen", @"BMC", @"BMC RACING TEAM"],
                 @[@"140", @"GRIVKO Andriy", @"AST", @"ASTANA PRO TEAM"],
                 @[@"57", @"MOSER Moreno", @"CAN", @"CANNONDALE"],
                 @[@"11", @"BOOM Lars", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"34", @"DENNIS Rohan", @"BMC", @"BMC RACING TEAM"],
                 @[@"33", @"DILLIER Silvan", @"BMC", @"BMC RACING TEAM"],
                 @[@"5", @"TERPSTRA Niki", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"36", @"OSS Daniel", @"BMC", @"BMC RACING TEAM"],
                 @[@"16", @"VAN EMDEN Jos", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"143", @"DOWSETT Alex", @"MOV", @"MOVISTAR TEAM"],
                 @[@"104", @"HEPBURN Michael", @"OGE", @"ORICA GreenEDGE"],
                 @[@"81", @"LANGEVELD Sebastian", @"GRS", @"GARMIN SHARP"],
                 @[@"84", @"NAVARDAUSKAS Ramunas", @"GRS", @"GARMIN SHARP"],
                 @[@"86", @"VAN BAARLE Dylan", @"GRS", @"GARMIN SHARP"],
                 @[@"53", @"KOREN Kristijan", @"CAN", @"CANNONDALE"],
                 @[@"127", @"SMUKULIS Gatis", @"KAT", @"TEAM KATUSHA"],
                 @[@"1", @"STYBAR Zdenek", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"31", @"GILBERT Philippe", @"BMC", @"BMC RACING TEAM"],
                 @[@"184", @"LAMPAERT Yves", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"44", @"HONDO Danilo", @"TFR", @"TREK FACTORY RACING"],
                 @[@"88", @"MILLAR David", @"GRS", @"GARMIN SHARP"],
                 @[@"106", @"KEUKELEIRE Jens", @"OGE", @"ORICA GreenEDGE"],
                 @[@"61", @"BOASSON HAGEN Edvald", @"SKY", @"TEAM SKY"],
                 @[@"38", @"VAN AVERMAET Greg", @"BMC", @"BMC RACING TEAM"],
                 @[@"74", @"GESCHKE Simon", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"125", @"PORSEV Alexandr", @"KAT", @"TEAM KATUSHA"],
                 @[@"64", @"KNEES Christian", @"SKY", @"TEAM SKY"],
                 @[@"17", @"VANMARCKE Sep", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"124", @"KUZNETSOV Viacheslav", @"KAT", @"TEAM KATUSHA"],
                 @[@"82", @"BAUER Jack", @"GRS", @"GARMIN SHARP"],
                 @[@"8", @"VERMOTE Julien", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"7", @"VAN KEIRSBULCK Guillaume", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"43", @"DEVOLDER Stijn", @"TFR", @"TREK FACTORY RACING"],
                 @[@"28", @"WELLENS Tim", @"LTB", @"LOTTO BELISOL"],
                 @[@"121", @"BRUTT Pavel", @"KAT", @"TEAM KATUSHA"],
                 @[@"107", @"MOURIS Jens", @"OGE", @"ORICA GreenEDGE"],
                 @[@"161", @"APPOLLONIO Davide", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"145", @"VENTOSO ALBERDI Francisco Jose", @"MOV", @"MOVISTAR TEAM"],
                 @[@"148", @"SÜTTERLIN Jasha", @"MOV", @"MOVISTAR TEAM"],
                 @[@"75", @"JANSE VAN RENSBURG Reinardt", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"21", @"GREIPEL André", @"LTB", @"LOTTO BELISOL"],
                 @[@"186", @"VAN HOECKE Gijs", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"116", @"ROUX Anthony", @"FDJ", @"FDJ.fr"],
                 @[@"141", @"GUTIERREZ PALACIOS José Ivan", @"MOV", @"MOVISTAR TEAM"],
                 @[@"96", @"ROVNI Ivan", @"TCS", @"TINKOFF-SAXO"],
                 @[@"23", @"BROECKX Stig", @"LTB", @"LOTTO BELISOL"],
                 @[@"166", @"GOUGEARD Alexis", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"122", @"IGNATYEV Mikhail", @"KAT", @"TEAM KATUSHA"],
                 @[@"112", @"BOUCHER David", @"FDJ", @"FDJ.fr"],
                 @[@"109", @"HOWARD Leigh", @"OGE", @"ORICA GreenEDGE"],
                 @[@"65", @"ROWE Luke", @"SKY", @"TEAM SKY"],
                 @[@"48", @"VAN POPPEL Danny", @"TFR", @"TREK FACTORY RACING"],
                 @[@"15", @"TANKINK Bram", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"24", @"ROELANDTS Jurgen", @"LTB", @"LOTTO BELISOL"],
                 @[@"178", @"NAULEAU Bryan", @"EUC", @"TEAM EUROPCAR"],
                 @[@"4", @"STEEGMANS Gert", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"69", @"PUCCIO Salvatore", @"SKY", @"TEAM SKY"],
                 @[@"85", @"NUYENS Nick", @"GRS", @"GARMIN SHARP"],
                 @[@"199", @"DE TROYER Tim", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"128", @"TCATEVICH Alexsei", @"KAT", @"TEAM KATUSHA"],
                 @[@"25", @"SIEBERG Marcel", @"LTB", @"LOTTO BELISOL"],
                 @[@"6", @"TRENTIN Matteo", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"154", @"CIMOLAI Davide", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"18", @"WYNANTS Maarten", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"2", @"BOONEN Tom", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"188", @"WAEYTENS Zico", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"198", @"DRUCKER Jean-Pierre", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"55", @"MARCATO Marco", @"CAN", @"CANNONDALE"],
                 @[@"153", @"POZZATO Filippo", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"94", @"MCCARTHY Jay", @"TCS", @"TINKOFF-SAXO"],
                 @[@"87", @"HAAS Nathan", @"GRS", @"GARMIN SHARP"],
                 @[@"123", @"KOCHETKOV Pavel", @"KAT", @"TEAM KATUSHA"],
                 @[@"83", @"FARRAR Tyler", @"GRS", @"GARMIN SHARP"],
                 @[@"114", @"OFFREDO Yoann", @"FDJ", @"FDJ.fr"],
                 @[@"95", @"PETROV Evgeny", @"TCS", @"TINKOFF-SAXO"],
                 @[@"3", @"KEISSE Iljo", @"OPQ", @"OMEGA PHARMA - QUICK-STEP CYCLING TEAM"],
                 @[@"105", @"HOWSON Damien", @"OGE", @"ORICA GreenEDGE"],
                 @[@"52", @"BETTIOL Alberto", @"CAN", @"CANNONDALE"],
                 @[@"157", @"RICHEZE Maximiliano Ariel", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"196", @"SELVAGGI Mirko", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"164", @"GASTAUER Ben", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"117", @"SOUPE Geoffrey", @"FDJ", @"FDJ.fr"],
                 @[@"47", @"VAN POPPEL Boy", @"TFR", @"TREK FACTORY RACING"],
                 @[@"66", @"STANNARD Ian", @"SKY", @"TEAM SKY"],
                 @[@"192", @"VEUCHELEN Frederik", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"160", @"POLANC Jan", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"162", @"BAGDONAS Gediminas", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"195", @"DE VREESE Laurens", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"26", @"VANENDERT Jelle", @"LTB", @"LOTTO BELISOL"],
                 @[@"92", @"KROON Karsten", @"TCS", @"TINKOFF-SAXO"],
                 @[@"183", @"STEELS Stijn", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"98", @"TRUSOV Nikolay", @"TCS", @"TINKOFF-SAXO"],
                 @[@"131", @"BOZIC Borut", @"AST", @"ASTANA PRO TEAM"],
                 @[@"179", @"GENE Yohann", @"EUC", @"TEAM EUROPCAR"],
                 @[@"22", @"DEBUSSCHERE Jens", @"LTB", @"LOTTO BELISOL"],
                 @[@"146", @"ROJAS GIL Jose Joaquin", @"MOV", @"MOVISTAR TEAM"],
                 @[@"118", @"VAUGRENARD Benoît", @"FDJ", @"FDJ.fr"],
                 @[@"156", @"MORI Manuele", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"45", @"NIZZOLO Giacomo", @"TFR", @"TREK FACTORY RACING"],
                 @[@"63", @"EARLE Nathan", @"SKY", @"TEAM SKY"],
                 @[@"152", @"BONIFAZIO Niccolo", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"78", @"VEELERS Tom", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"138", @"TLEUBAYEV Ruslan", @"AST", @"ASTANA PRO TEAM"],
                 @[@"54", @"LONGO BORGHINI Paolo", @"CAN", @"CANNONDALE"],
                 @[@"194", @"JANS Roy", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"175", @"JEROME Vincent", @"EUC", @"TEAM EUROPCAR"],
                 @[@"77", @"STAMSNIJDER Tom", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"111", @"BOUHANNI Nacer", @"FDJ", @"FDJ.fr"],
                 @[@"76", @"MEZGEC Luka", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"72", @"BULGAC Brian", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"58", @"SABATINI Fabio", @"CAN", @"CANNONDALE"],
                 @[@"177", @"MARTINEZ Yannick", @"EUC", @"TEAM EUROPCAR"],
                 @[@"102", @"GOSS Matthew Harley", @"OGE", @"ORICA GreenEDGE"],
                 @[@"103", @"HAYMAN Mathew", @"OGE", @"ORICA GreenEDGE"],
                 @[@"67", @"SUTTON Christopher", @"SKY", @"TEAM SKY"],
                 @[@"197", @"VAN MELSEN Kevin", @"WGG", @"WANTY - GROUPE GOBERT"],
                 @[@"165", @"GRETSCH Patrick", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"176", @"LAMOISSON Morgan", @"EUC", @"TEAM EUROPCAR"],
                 @[@"91", @"BRESCHEL Matti", @"TCS", @"TINKOFF-SAXO"],
                 @[@"14", @"MOLLEMA Bauke", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"113", @"JEANNESSON Arnold", @"FDJ", @"FDJ.fr"],
                 @[@"155", @"FAVILLI Elia", @"LAM", @"LAMPRE-MERIDA"],
                 @[@"187", @"VAN BILSEN Kenneth", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"185", @"SPRENGERS Thomas", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"180", @"PICHOT Alexandre", @"EUC", @"TEAM EUROPCAR"],
                 @[@"182", @"DECLERCQ Tim", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"12", @"LEEZER Thomas", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"136", @"HUFFMAN Evan", @"AST", @"ASTANA PRO TEAM"],
                 @[@"110", @"KRUOPIS Aidis", @"OGE", @"ORICA GreenEDGE"],
                 @[@"93", @"KOLÁR Michal", @"TCS", @"TINKOFF-SAXO"],
                 @[@"32", @"BURGHARDT Marcus", @"BMC", @"BMC RACING TEAM"],
                 @[@"42", @"ALAFACI Eugenio", @"TFR", @"TREK FACTORY RACING"],
                 @[@"56", @"MARINO Jean Marc", @"CAN", @"CANNONDALE"],
                 @[@"73", @"CURVERS Roy", @"GIA", @"TEAM GIANT-SHIMANO"],
                 @[@"137", @"IGLINSKIY Valentin", @"AST", @"ASTANA PRO TEAM"],
                 @[@"13", @"MARKUS Barry", @"BEL", @"BELKIN-PRO CYCLING TEAM"],
                 @[@"174", @"HUREL Tony", @"EUC", @"TEAM EUROPCAR"],
                 @[@"142", @"QUINTANA Dayer", @"MOV", @"MOVISTAR TEAM"],
                 @[@"134", @"GUARDINI Andrea", @"AST", @"ASTANA PRO TEAM"],
                 @[@"168", @"KERN Julian", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"147", @"SANZ Enrique", @"MOV", @"MOVISTAR TEAM"],
                 @[@"115", @"PICHON Laurent", @"FDJ", @"FDJ.fr"],
                 @[@"132", @"DYACHENKO Alexandr", @"AST", @"ASTANA PRO TEAM"],
                 @[@"163", @"DANIEL Maxime", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"169", @"CHAINEL Steve", @"ALM", @"AG2R LA MONDIALE"],
                 @[@"144", @"LASTRAS GARCIA Pablo", @"MOV", @"MOVISTAR TEAM"],
                 @[@"133", @"KAMYSHEV Arman", @"AST", @"ASTANA PRO TEAM"],
                 @[@"181", @"VAN STAEYEN Michael", @"TSV", @"TOPSPORT VLAANDEREN - BALOISE"],
                 @[@"29", @"DOCKX Gert", @"LTB", @"LOTTO BELISOL"],
                 @[@"173", @"DUCHESNE Antoine", @"EUC", @"TEAM EUROPCAR"]];
    TEST_ARRAYS(actual, expected);
}

- (void)testGithubIssue79 {
    NSString *scsv = @"16681;6;Orehovyj boulevard, ul. Musy Dzhalilja (odd side);20;out;55.6141571054;37.7460757208;800;34;34;0;0;0;0;0;1";
    NSArray *parsed = [scsv componentsSeparatedByDelimiter:';'];
    NSArray *expected = @[@[@"16681",@"6",@"Orehovyj boulevard, ul. Musy Dzhalilja (odd side)",@"20",@"out",@"55.6141571054",@"37.7460757208",@"800",@"34",@"34",@"0",@"0",@"0",@"0",@"0",@"1"]];
    
    TEST_ARRAYS(parsed, expected);
    
    NSURL *url = [self temporaryURLForDelimitedString:scsv];
    parsed = [NSArray arrayWithContentsOfDelimitedURL:url delimiter:';'];
    
    TEST_ARRAYS(parsed, expected);
    
    // Rather than embedding the entire contents of this file within the source here,
    // I'm going to assume that if there are the correct number of records and
    // the correct number of fields per record, then it probably parsed correctly.
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *fileURL = [bundle URLForResource:@"Issue79" withExtension:@"csv"];
    NSArray *contents = [NSArray arrayWithContentsOfDelimitedURL:fileURL delimiter:';'];
    XCTAssertEqual(contents.count, 1112, @"Unexpected number of lines: %ld", contents.count);
    [contents enumerateObjectsUsingBlock:^(NSArray *line, NSUInteger idx, BOOL *stop) {
        XCTAssertEqual(line.count, 14, @"Unexpected number of lines on record %ld: %ld", idx, line.count);
    }];
    
    // try loading the file as an array of ordered dictionaries
    contents = [NSArray arrayWithContentsOfDelimitedURL:fileURL options:CHCSVParserOptionsUsesFirstLineAsKeys delimiter:';'];
    XCTAssertEqual(contents.count, 1111, @"Unexpected number of lines: %ld", contents.count);
    NSArray *keys = @[@"id_entrance",@"name",@"id_station",@"direction",@"lat",@"lon",@"max_width",@"min_step",@"min_step_ramp",@"lift",@"lift_minus_step",@"min_rail_width",@"max_rail_width",@"max_angle"];
    [contents enumerateObjectsUsingBlock:^(CHCSVOrderedDictionary *record, NSUInteger idx, BOOL *stop) {
        XCTAssertEqual(record.count, 14, @"Unexpected number of lines on record %ld: %ld", idx, record.count);
        XCTAssertEqualObjects(record.allKeys, keys, @"Unexpected record keys: %@", record.allKeys);
    }];
}

- (void)testEmptyFields {
    NSString *csv = COMMA COMMA;
    NSArray *expected = @[@[EMPTY, EMPTY, EMPTY]];
    TEST(csv, expected);
}

- (void)testSimpleWithInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleWithDoubledInnerQuote {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE DOUBLEQUOTE FIELD3]];
    TEST(csv, expected);
}

- (void)testInterspersedDoubleQuotes {
    NSString *csv = FIELD1 COMMA FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, FIELD2 DOUBLEQUOTE FIELD3 DOUBLEQUOTE]];
    TEST(csv, expected);
}

- (void)testSimpleQuoted {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *expected = @[@[QUOTED_FIELD1, QUOTED_FIELD2, QUOTED_FIELD3]];
    TEST(csv, expected);
}

- (void)testSimpleQuotedSanitized {
    NSString *csv = QUOTED_FIELD1 COMMA QUOTED_FIELD2 COMMA QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testSimpleMultiline {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3], @[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected);
}

- (void)testQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE]];
    TEST(csv, expected);
}

- (void)testSanitizedQuotedDelimiter {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE FIELD2 COMMA FIELD3 DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, FIELD2 COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testQuotedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *expected = @[@[FIELD1, DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE], @[FIELD2]];
    TEST(csv, expected);
}

- (void)testSanitizedMultiline {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE MULTILINE_FIELD DOUBLEQUOTE NEWLINE FIELD2;
    NSArray *expected = @[@[FIELD1, MULTILINE_FIELD], @[FIELD2]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    TEST(csv, expected);
}

- (void)testTrimmedWhitespace {
    NSString *csv = FIELD1 COMMA SPACE SPACE SPACE FIELD2 COMMA FIELD3 SPACE SPACE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsTrimsWhitespace);
}

- (void)testSanitizedQuotedWhitespace {
    NSString *csv = FIELD1 COMMA DOUBLEQUOTE SPACE SPACE SPACE FIELD2 DOUBLEQUOTE COMMA DOUBLEQUOTE FIELD3 SPACE SPACE SPACE DOUBLEQUOTE;
    NSArray *expected = @[@[FIELD1, SPACE SPACE SPACE FIELD2, FIELD3 SPACE SPACE SPACE]];
    TEST(csv, expected, CHCSVParserOptionsSanitizesFields);
}

- (void)testUnrecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *expected = @[@[FIELD1], @[OCTOTHORPE FIELD2]];
    TEST(csv, expected);
}

- (void)testRecognizedComment {
    NSString *csv = FIELD1 NEWLINE OCTOTHORPE FIELD2;
    NSArray *expected = @[@[FIELD1]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesComments);
}

- (void)testTrailingNewline {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE;
    NSArray *expected = @[@[FIELD1, FIELD2]];
    TEST(csv, expected);
}

- (void)testTrailingSpace {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2], @[SPACE]];
    TEST(csv, expected);
}

- (void)testTrailingTrimmedSpace {
    NSString *csv = FIELD1 COMMA FIELD2 NEWLINE SPACE;
    NSArray *expected = @[@[FIELD1, FIELD2], @[EMPTY]];
    TEST(csv, expected, CHCSVParserOptionsTrimsWhitespace);
}

- (void)testEmoji {
    NSString *csv = @"1️⃣,2️⃣,3️⃣,4️⃣,5️⃣" NEWLINE @"6️⃣,7️⃣,8️⃣,9️⃣,0️⃣";
    NSArray *expected = @[@[@"1️⃣",@"2️⃣",@"3️⃣",@"4️⃣",@"5️⃣"],@[@"6️⃣",@"7️⃣",@"8️⃣",@"9️⃣",@"0️⃣"]];
    TEST(csv, expected);
}

#pragma mark - Testing Backslashes

- (void)testUnrecognizedBackslash {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH, FIELD3]];
    TEST(csv, expected);
}

- (void)testBackslashEscapedComma {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes);
}

- (void)testSantizedBackslashEscapedComma {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH COMMA FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 COMMA FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes | CHCSVParserOptionsSanitizesFields);
}

- (void)testBackslashEscapedNewline {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH NEWLINE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 BACKSLASH NEWLINE FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes);
}

- (void)testSantizedBackslashEscapedNewline {
    NSString *csv = FIELD1 COMMA FIELD2 BACKSLASH NEWLINE FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2 NEWLINE FIELD3]];
    TEST(csv, expected, CHCSVParserOptionsRecognizesBackslashesAsEscapes | CHCSVParserOptionsSanitizesFields);
}

#pragma mark - Testing First Line as Keys

- (void)testOrderedDictionary {
    CHCSVOrderedDictionary *dictionary = [CHCSVOrderedDictionary dictionaryWithObjects:@[FIELD1, FIELD2, FIELD3] forKeys:@[FIELD1, FIELD2, FIELD3]];
    NSArray *expected = @[FIELD1, FIELD2, FIELD3];
    XCTAssertEqualObjects(dictionary.allKeys, expected, @"Unexpected field order");
    
    XCTAssertEqualObjects(dictionary[0], FIELD1, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[1], FIELD2, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[2], FIELD3, @"Unexpected field");
    
    XCTAssertEqualObjects(dictionary[FIELD1], FIELD1, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[FIELD2], FIELD2, @"Unexpected field");
    XCTAssertEqualObjects(dictionary[FIELD3], FIELD3, @"Unexpected field");
    
    NSDictionary *regularDictionary = @{FIELD1 : FIELD1, FIELD2 : FIELD2, FIELD3 : FIELD3 };
    XCTAssertNotEqualObjects(regularDictionary, expected, @"Somehow equal??");
}

- (void)testFirstLineAsKeys {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3;
    NSArray *expected = @[
                          [CHCSVOrderedDictionary dictionaryWithObjects:@[FIELD1, FIELD2, FIELD3] forKeys:@[FIELD1, FIELD2, FIELD3]]
                          ];
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
}

- (void)testFirstLineAsKeys_SingleLine {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE;
    NSArray *expected = @[];
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
    
    csv = FIELD1 COMMA FIELD2 COMMA FIELD3;
    TEST(csv, expected, CHCSVParserOptionsUsesFirstLineAsKeys);
}

- (void)testFirstLineAsKeys_MismatchedFieldCount {
    NSString *csv = FIELD1 COMMA FIELD2 COMMA FIELD3 NEWLINE FIELD1 COMMA FIELD2 COMMA FIELD3 COMMA FIELD1;
    
    NSError *error = nil;
    (void)[csv componentsSeparatedByDelimiter:[COMMA characterAtIndex:0] options:CHCSVParserOptionsUsesFirstLineAsKeys error:&error];
    XCTAssertNotNil(error, @"Expected error");
    XCTAssertEqualObjects(error.domain, CHCSVErrorDomain, @"Unexpected error");
    XCTAssertEqual(error.code, CHCSVErrorCodeIncorrectNumberOfFields, @"Unexpected error");
}

#pragma mark - Testing Valid Delimiters

- (void)testAllowedDelimiter_Octothorpe {
    NSString *csv = FIELD1 OCTOTHORPE FIELD2 OCTOTHORPE FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'#'];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Octothorpe {
    NSString *csv = FIELD1 OCTOTHORPE FIELD2 OCTOTHORPE FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'#' options:CHCSVParserOptionsRecognizesComments], @"failed");
}

- (void)testAllowedDelimiter_Backslash {
    NSString *csv = FIELD1 BACKSLASH FIELD2 BACKSLASH FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'\\'];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Backslash {
    NSString *csv = FIELD1 BACKSLASH FIELD2 BACKSLASH FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'\\' options:CHCSVParserOptionsRecognizesBackslashesAsEscapes], @"failed");
}

- (void)testAllowedDelimiter_Equal {
    NSString *csv = FIELD1 EQUAL FIELD2 EQUAL FIELD3;
    NSArray *actual = [csv componentsSeparatedByDelimiter:'='];
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST_ARRAYS(actual, expected);
}

- (void)testDisallowedDelimiter_Equal {
    NSString *csv = FIELD1 EQUAL FIELD2 EQUAL FIELD3;
    
    XCTAssertThrows([csv componentsSeparatedByDelimiter:'=' options:CHCSVParserOptionsRecognizesLeadingEqualSign], @"failed");
}

#pragma mark - Testing Leading Equal

- (void)testLeadingEqual {
    NSString *csv = FIELD1 COMMA EQUAL QUOTED_FIELD2 COMMA EQUAL QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, EQUAL QUOTED_FIELD2, EQUAL QUOTED_FIELD3]];
    
    TEST(csv, expected, CHCSVParserOptionsRecognizesLeadingEqualSign);
}

- (void)testSanitizedLeadingEqual {
    NSString *csv = FIELD1 COMMA EQUAL QUOTED_FIELD2 COMMA EQUAL QUOTED_FIELD3;
    NSArray *expected = @[@[FIELD1, FIELD2, FIELD3]];
    
    TEST(csv, expected, CHCSVParserOptionsRecognizesLeadingEqualSign | CHCSVParserOptionsSanitizesFields);
}

@end
