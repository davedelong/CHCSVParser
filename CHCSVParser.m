//
//  CHCSVParser.m
//  CHCSVParser
//
//  Created by Dave DeLong on 9/22/12.
//
//

#import "Parser.h"

#define CHUNK_SIZE 512
#define DOUBLE_QUOTE '"'
#define COMMA ','
#define OCTOTHORPE '#'
#define BACKSLASH '\\'

@implementation CHCSVParser {
    NSInputStream *_stream;
    NSStringEncoding _streamEncoding;
    NSMutableData *_stringBuffer;
    NSMutableString *_string;
    NSCharacterSet *_validFieldCharacters;
    
    NSInteger _nextIndex;
    
    NSRange _fieldRange;
    NSMutableString *_sanitizedField;
    
    unichar _delimiter;
    
    NSError *_error;
    
    NSUInteger _currentRecord;
    BOOL _cancelled;
}

- (id)initWithCSVString:(NSString *)csv {
    NSStringEncoding encoding = NSUTF8StringEncoding;
    NSInputStream *stream = [NSInputStream inputStreamWithData:[csv dataUsingEncoding:encoding]];
    return [self initWithInputStream:stream usedEncoding:&encoding delimiter:COMMA];
}

- (id)initWithContentsOfCSVFile:(NSString *)csvFilePath {
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:csvFilePath];
    NSStringEncoding encoding = NSUTF8StringEncoding;
    return [self initWithInputStream:stream usedEncoding:&encoding delimiter:COMMA];
}

- (id)initWithInputStream:(NSInputStream *)stream usedEncoding:(NSStringEncoding *)encoding delimiter:(unichar)delimiter {
    NSParameterAssert(stream);
    NSParameterAssert(delimiter);
    NSAssert([[NSCharacterSet newlineCharacterSet] characterIsMember:_delimiter] == NO, @"The field delimiter may not be a newline");
    NSAssert(_delimiter != DOUBLE_QUOTE, @"The field delimiter may not be a double quote");
    NSAssert(_delimiter != OCTOTHORPE, @"The field delimiter may not be an octothorpe");
    
    self = [super init];
    if (self) {
        _stream = [stream retain];
        [_stream open];
        
        _stringBuffer = [[NSMutableData alloc] init];
        _string = [[NSMutableString alloc] init];
        
        _delimiter = delimiter;
        
        _nextIndex = 0;
        _recognizesBackslashesAsEscapes = YES;
        _sanitizesFields = NO;
        _sanitizedField = [[NSMutableString alloc] init];
        
        NSMutableCharacterSet *m = [[NSCharacterSet newlineCharacterSet] mutableCopy];
        NSString *invalid = [NSString stringWithFormat:@"%c%C", DOUBLE_QUOTE, _delimiter];
        [m addCharactersInString:invalid];
        _validFieldCharacters = [[m invertedSet] retain];
        [m release];
        
        if (encoding == NULL || *encoding == 0) {
            // we need to determine the encoding
            [self _sniffEncoding];
            if (encoding) {
                *encoding = _streamEncoding;
            }
        } else {
            _streamEncoding = *encoding;
        }
    }
    return self;
}

- (void)dealloc {
    [_stream close];
    [_stream release];
    [_stringBuffer release];
    [_string release];
    [_sanitizedField release];
    [_validFieldCharacters release];
    [super dealloc];
}

#pragma mark -

- (void)_sniffEncoding {
    uint8_t bytes[CHUNK_SIZE];
    NSUInteger readLength = [_stream read:bytes maxLength:CHUNK_SIZE];
    [_stringBuffer appendBytes:bytes length:readLength];
    
    NSUInteger bufferLength = [_stringBuffer length];
    if (bufferLength > 0) {
        NSStringEncoding encoding = NSUTF8StringEncoding;
        
        UInt8* bytes = (UInt8*)[_stringBuffer bytes];
        if (bufferLength > 3 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF) {
            encoding = NSUTF32BigEndianStringEncoding;
        } else if (bufferLength > 3 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00) {
            encoding = NSUTF32LittleEndianStringEncoding;
        } else if (bufferLength > 1 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
            encoding = NSUTF16BigEndianStringEncoding;
        } else if (bufferLength > 1 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
            encoding = NSUTF16LittleEndianStringEncoding;
        } else if (bufferLength > 2 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
            encoding = NSUTF8StringEncoding;
        } else {
            NSString *bufferAsUTF8 = [[NSString alloc] initWithData:_stringBuffer encoding:NSUTF8StringEncoding];
            if (bufferAsUTF8 != nil) {
                encoding = NSUTF8StringEncoding;
                [bufferAsUTF8 release];
            } else {
                NSLog(@"unable to determine stream encoding; assuming MacOSRoman");
                encoding = NSMacOSRomanStringEncoding;
            }
        }
        
        _streamEncoding = encoding;
    }
}

- (void)_loadMoreIfNecessary {
    NSUInteger stringLength = [_string length];
    NSUInteger reloadPortion = stringLength / 3;
    if (reloadPortion < 10) { reloadPortion = 10; }
    
    if (_nextIndex+reloadPortion >= stringLength && [_stream hasBytesAvailable]) {
        // read more
        uint8_t buffer[CHUNK_SIZE];
        NSInteger readBytes = [_stream read:buffer maxLength:CHUNK_SIZE];
        if (readBytes > 0) {
            [_stringBuffer appendBytes:buffer length:readBytes];
            
            NSUInteger readLength = [_stringBuffer length];
            while (readLength > 0) {
                NSString *readString = [[NSString alloc] initWithBytes:[_stringBuffer bytes] length:readLength encoding:_streamEncoding];
                if (readString == nil) {
                    readLength--;
                } else {
                    [_string appendString:readString];
                    [readString release];
                    break;
                }
            };
            
            [_stringBuffer replaceBytesInRange:NSMakeRange(0, readLength) withBytes:NULL length:0];
        }
    }
}

- (void)_advance {
    [self _loadMoreIfNecessary];
    _nextIndex++;
}

- (unichar)_peekCharacter {
    [self _loadMoreIfNecessary];
    if (_nextIndex >= [_string length]) { return '\0'; }
    
    return [_string characterAtIndex:_nextIndex];
}

- (unichar)_peekPeekCharacter {
    [self _loadMoreIfNecessary];
    NSUInteger nextNextIndex = _nextIndex+1;
    if (nextNextIndex >= [_string length]) { return '\0'; }
    
    return [_string characterAtIndex:nextNextIndex];
}

#pragma mark -

- (void)parse {
    [self _beginDocument];
    
    _currentRecord = 0;
    while ([self _parseRecord]) {
        ; // yep;
    }
    
    if (_error != nil) {
        [self _error];
    } else {
        [self _endDocument];
    }
}

- (void)cancelParsing {
    _cancelled = YES;
}

- (BOOL)_parseRecord {
    while ([self _peekCharacter] == OCTOTHORPE) {
        [self _parseComment];
    }
    
    [self _beginRecord];
    while (1) {
        if (![self _parseField]) {
            break;
        }
        if (![self _parseDelimiter]) {
            break;
        }
    }    
    [self _parseNewline];
    [self _endRecord];
    
    return (_error == nil);
}

- (BOOL)_parseNewline {
    if (_cancelled) { return NO; }
    
    NSUInteger charCount = 0;
    while ([[NSCharacterSet newlineCharacterSet] characterIsMember:[self _peekCharacter]]) {
        charCount++;
        [self _advance];
    }
    return (charCount > 0);
}

- (BOOL)_parseComment {
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    
    BOOL isBackslashEscaped = NO;
    while (1) {
        if (isBackslashEscaped == NO) {
            unichar next = [self _peekCharacter];
            if (next == BACKSLASH && _recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self _advance];
            } else if ([newlines characterIsMember:next] == NO) {
                [self _advance];
            } else {
                // it's a newline
                break;
            }
        } else {
            isBackslashEscaped = YES;
            [self _advance];
        }
    }
    return [self _parseNewline];
}

- (BOOL)_parseField {
    if (_cancelled) { return NO; }
    
    [_sanitizedField setString:@""];
    if ([self _peekCharacter] == DOUBLE_QUOTE) {
        return [self _parseEscapedField];
    } else {
        return [self _parseUnescapedField];
    }
}

- (BOOL)_parseEscapedField {
    [self _beginField];
    [self _advance]; // consume the opening double quote
    
    NSCharacterSet *newlines = [NSCharacterSet newlineCharacterSet];
    BOOL isBackslashEscaped = NO;
    while (1) {
        unichar next = [self _peekCharacter];
        if (next == '\0') { break; }
        
        if (isBackslashEscaped == NO) {
            if (next == BACKSLASH && _recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self _advance]; // consume the backslash
            } else if ([_validFieldCharacters characterIsMember:next] ||
                       [newlines characterIsMember:next] ||
                       next == COMMA) {
                [_sanitizedField appendFormat:@"%C", next];
                [self _advance];
            } else if (next == DOUBLE_QUOTE && [self _peekPeekCharacter] == DOUBLE_QUOTE) {
                [_sanitizedField appendFormat:@"%C", next];
                [self _advance];
                [self _advance];
            } else {
                // not valid, or it's not a doubled double quote
                break;
            }
        } else {
            [_sanitizedField appendFormat:@"%C", next];
            isBackslashEscaped = NO;
            [self _advance];
        }
    }
    
    if ([self _peekCharacter] == DOUBLE_QUOTE) {
        [self _advance];
        [self _endField];
        return YES;
    }
    
    return NO;
}

- (BOOL)_parseUnescapedField {
    [self _beginField];
    
    BOOL isBackslashEscaped = NO;
    while (1) {
        unichar next = [self _peekCharacter];
        if (next == '\0') { break; }
        
        if (isBackslashEscaped == NO) {
            if (next == BACKSLASH && _recognizesBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                [self _advance];
            } else if ([_validFieldCharacters characterIsMember:next]) {
                [_sanitizedField appendFormat:@"%C", next];
                [self _advance];
            } else {
                break;
            }
        } else {
            isBackslashEscaped = NO;
            [_sanitizedField appendFormat:@"%C", next];
            [self _advance];
        }
    }
    
    [self _endField];
    return YES;
}

- (BOOL)_parseDelimiter {
    unichar next = [self _peekCharacter];
    if (next == _delimiter) {
        [self _advance];
        return YES;
    }
    if (next != '\0' && [[NSCharacterSet newlineCharacterSet] characterIsMember:next] == NO) {
        NSString *description = [NSString stringWithFormat:@"Unexpected delimiter. Expected '%C', but got '%C'", _delimiter, [self _peekCharacter]];
        _error = [[NSError alloc] initWithDomain:@"com.davedelong.csv" code:1 userInfo:@{NSLocalizedDescriptionKey : description}];
    }
    return NO;
}

- (void)_beginDocument {
    if ([_delegate respondsToSelector:@selector(parserDidBeginDocument:)]) {
        [_delegate parserDidBeginDocument:self];
    }
}

- (void)_endDocument {
    if ([_delegate respondsToSelector:@selector(parserDidEndDocument:)]) {
        [_delegate parserDidEndDocument:self];
    }
}

- (void)_beginRecord {
    if (_cancelled) { return; }
    
    _currentRecord++;
    if ([_delegate respondsToSelector:@selector(parser:didBeginRecord:)]) {
        [_delegate parser:self didBeginRecord:_currentRecord];
    }
}

- (void)_endRecord {
    if (_cancelled) { return; }
    
    if ([_delegate respondsToSelector:@selector(parser:didEndRecord:)]) {
        [_delegate parser:self didEndRecord:_currentRecord];
    }
}

- (void)_beginField {
    if (_cancelled) { return; }
    
    _fieldRange.location = _nextIndex;
}

- (void)_endField {
    if (_cancelled) { return; }
    
    _fieldRange.length = (_nextIndex - _fieldRange.location);
    NSString *field = [_string substringWithRange:_fieldRange];
    
    if (_sanitizesFields) {
        field = [[_sanitizedField copy] autorelease];
    }
    
    if ([_delegate respondsToSelector:@selector(parser:didReadField:)]) {
        [_delegate parser:self didReadField:field];
    } else {
        NSLog(@"%@", field);
    }
    
    [_string replaceCharactersInRange:NSMakeRange(0, NSMaxRange(_fieldRange)) withString:@""];
    _nextIndex = 0;
}

- (void)_error {
    if (_cancelled) { return; }
    
    if ([_delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
        [_delegate parser:self didFailWithError:_error];
    } else {
        NSLog(@"error parsing: %@", _error);
    }
}

@end
