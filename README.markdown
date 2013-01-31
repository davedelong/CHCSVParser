#CHCSVParser

`CHCSVParser` is an Objective-C parser for CSV files.

##Supported Platforms

- Mac OS X 10.7+
- iOS 6+

##Usage

In order to use `CHCSVParser`, you'll need to include the following two files in your project:

- `CHCSVParser.h`
- `CHCSVParser.m`

`CHCSVParser` can be safely compiled with or without ARC enabled.

###Parsing
A `CHCSVParser` works very similarly to an `NSXMLParser`, in that it synchronously parses the data and invokes delegate callback methods to let you know that it has found a field, or has finished reading a line, or has encountered a syntax error.

A `CHCSVParser` can be created in one of three ways:

1. With a path to a file
2. With the contents of an `NSString`
3. With an `NSInputStream`

`CHCSVParser` can be configured to parse other "character-seperated" file formats, such as "TSV" (tab-seperated).  You can specify the delimiter of the parser during initialization.  The delimiter can only be one character in length, and cannot be any newline character, `#`, `"`, or `\`.

By default, `CHCSVParser` will not sanitize the output of the fields; in other words, individual fields will be returned exactly as they are found in the CSV file.  However, if you wish the fields to be cleaned (surrounding double quotes stripped, characters unescaped, etc), you can specify this by setting the `sanitizesFields` property to `YES`.

There are two other properties (`recognizesBackslashesAsEscapes` and `recognizesComments`) that are also disabled by default.  The former allows the parser to recognize `\"` as an escaped double quote (in addition to the standard `""`), and the latter will cause the parser to skip over lines that begin with the octothorpe (`#`).

###Writing
A `CHCSVWriter` has several methods for constructing CSV files:

`-writeField:` accepts an object and writes its `-description` (after being properly escaped) out to the CSV file.  It will also write field seperator (`,`) if necessary.  You may pass an empty string (`@""`) or `nil` to write an empty field.

`-finishLine` is used to terminate the current CSV line.  If you do not invoke `-finishLine`, then all of your CSV fields will be on a single line.

`-writeLineOfFields:` accepts an array of objects, sends each one to `-writeField:`, and then invokes `-finishLine`.

`-writeComment:` accepts a string and writes it out to the file as a CSV-style comment.

If you wish to write CSV directly into an `NSString`, you should create an `NSOutputStream` for writing to memory and use that as the output stream of the `CHCSVWriter`.  For an example of how to do this, see the `-[NSArray(CHCSVAdditions) CSVString]` method.

Like `CHCSVParser`, `CHCSVWriter` can be customized with a delimiter other than `,` during initialization.

###Convenience Methods

There are a couple of category methods on `NSArray` and `NSString` to simplify the common reading and writing CSV tasks.


##Data Encoding
`CHCSVParser` relies on knowing the encoding of the CSV file.  It should work with pretty much any kind of file encoding, if you can provide what that encoding is.  If you do not know the encoding of the file, then `CHCSVParser` can make a naïve guess.  `CHCSVParser` will try to guess the encoding of the file from among these options:

 - MacOS Roman (`NSMacOSRomanStringEncoding`; the default/fallback encoding)
 - UTF-8 (`NSUTF8StringEncoding`)
 - UTF-16BE (`NSUTF16BigEndianStringEncoding`)
 - UTF-16LE (`NSUTF16LittleEndianStringEncoding`)
 - UTF-32BE (`NSUTF32BigEndianStringEncoding`)
 - UTF-32LE (`NSUTF32LittleEndianStringEncoding`)
 - ISO 2022-KR (`kCFStringEncodingISO_2022_KR`)
 
##Performance
`CHCSVParser` is conscious of low-memory environments, such as the iPhone or iPad.  It can safely parse very large CSV files, because it only loads portions of the file into memory at a single time.
 
##Credits & Contributors

`CHCSVParser` was written by [Dave DeLong][1].

`CHCSVParser` uses code to discover file encoding that was provided by [Rainer Brockerhoff][2].

  [1]: http://davedelong.com
  [2]: http://brockerhoff.net
  
##License

`CHCSVParser` is licensed under the MIT license, which is reproduced in its entirety here:


>Copyright (c) 2012 Dave DeLong
>
>Permission is hereby granted, free of charge, to any person obtaining a copy
>of this software and associated documentation files (the "Software"), to deal
>in the Software without restriction, including without limitation the rights
>to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>copies of the Software, and to permit persons to whom the Software is
>furnished to do so, subject to the following conditions:
>
>The above copyright notice and this permission notice shall be included in
>all copies or substantial portions of the Software.
>
>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
>THE SOFTWARE.
