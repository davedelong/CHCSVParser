//
//  CHCSVParserBlocks.h
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

#import "CHCSVParser.h"

/**
 * CSV parser with code blocks.
 * Do not set the delegate for this class. Instead use the provied callbacks.
 */
@interface CHCSVParserBlocks : CHCSVParser<CHCSVParserDelegate>

/**
 *  Indicates that the parser has started parsing the stream
 */
@property (nonatomic, copy) void(^didBeginDocumentCallback)();

/**
 *  Indicates that the parser has successfully finished parsing the stream
 *
 *  This callback is not invoked if any error is encountered
 */
@property (nonatomic, copy) void(^didEndDocumentCallback)();

/**
 *  Indicates the parser has started parsing a line
 *
 *  @param recordNumber The 1-based number of the record
 */
@property (nonatomic, copy) void(^didBeginLineCallback)(NSUInteger recordNumber);

/**
 *  Indicates the parser has finished parsing a line
 *
 *  @param recordNumber The 1-based number of the record
 */
@property (nonatomic, copy) void(^didEndLineCallback)(NSUInteger recordNumber);

/**
 *  Indicates the parser has parsed a field on the current line
 *
 *  @param field      The parsed string. If configured to do so, this string may be sanitized and trimmed
 *  @param fieldIndex The 0-based index of the field within the current record
 */
@property (nonatomic, copy) void(^didReadFieldCallback)(NSString *field, NSInteger fieldIndex);

/**
 *  Indicates the parser has encountered a comment
 *
 *  This method is only invoked if @c CHCSVParser.recognizesComments is @c YES
 *
 *  @param comment The parsed comment
 */
@property (nonatomic, copy) void(^didReadCommentCallback)(NSString *comment);

/**
 *  Indicates the parser encounter an error while parsing
 *
 *  @param error  The @c NSError instance
 */
@property (nonatomic, copy) void(^didFailWithErrorCallback)(NSError *error);

@end
