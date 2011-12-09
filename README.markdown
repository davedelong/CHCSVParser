#CHCSVParser

`CHCSVParser` is an Objective-C parser for CSV files.

##Supported Platforms

- Mac OS X 10.5+
- iOS 3+

##Usage

###Parsing

In order to use `CHCSVParser`, you'll need to include the following three files in your project:

- `CHCSV.h`
- `CHCSVParser.*`

These four files are optional, though they do simplify things:

- `NSArray+CHCSVAdditions.*`
- `NSString+CHCSVAdditions.*`

###Writing

In order to use `CHCSVWriter`, you'll need to include the following two files in your project:

- `CHCSVWriter.*`

###Parsing
A `CHCSVParser` works very similarly to an `NSXMLParser`, in that it synchronously parses the data and invokes delegate callback methods to let you know that it has found a field, or has finished reading a line, or has encountered a syntax error.

A `CHCSVParser` can be created in one of three ways:

1. With a path to a file
2. With the contents of an `NSString`
3. With an `NSInputStream`

`CHCSVParser` can be configured to parse other "character-seperated" file formats, such as "TSV" (tab-seperated).  You can change the delimiter of the parser prior to beginning parsing.  The delimiter can only be one character in length, and cannot be any newline character, `#`, `"`, or `\`.

###Writing
A `CHCSVWriter` has several methods for constructing CSV files:

`-writeField:` accepts an object and writes its `-description` (after being properly escaped) out to the CSV file.  It will also write field seperator (`,`) if necessary.  You may pass an empty string (`@""`) or `nil` to write an empty field.

`-writeFields:` accepts a comma-delimited and nil-terminated list of objects and  sends each one to `-writeField:`.

`-writeLine` is used to terminate the current CSV line.  If you do not invoke `-writeLine`, then all of your CSV fields will be on a single line.

`-writeLineOfFields:` accepts a comma-delimited and nil-terminated list of objects, sends each one to `-writeField:`, and then invokes `-writeLine`.

`-writeLineWithFields:` accepts an array of objects, sends each one to `-writeField:`, and then invokes `-writeLine`.

`-writeCommentLine:` accepts a string and writes it out to the file as a CSV-style comment.

In addition to writing to a file, `CHCSVWriter` can be initialized for writing directly to an `NSString`.

Like `CHCSVParser`, `CHCSVWriter` can be customized with a delimiter other than `,` prior to beginning writing.

###Convenience Methods
Included in the code is an `NSArray` category to simplify reading from and writing to CSV files.  In order to use these methods, you must also include `NSArray+CHCSVAdditions.*` in your project.  This category adds many methods to `NSArray` to simplify the process of converting a file, string, or input stream into an `NSArray` of `NSArrays` of `NSStrings`.  There are also methods to write the array to a CSV file (or with a custom delimiter), or to convert it into an `NSString` of well-formed CSV.

There is also an `NSString` category to parse an `NSString` of CSV data into an `NSArray` of `NSArray` objects.  This method is `-[NSString CSVComponents]`.

###General Use

The simplest use of `CHCSVParser` is to include all of the files mentioned above in your project.  To use any of the CSV parsing or writing functionality, simply `#import "CHCSV.h"` and use any of the classes and categories as you'd like.


##Data Encoding
`CHCSVParser` relies on knowing the encoding of the CSV file.  It should work with pretty much any kind of file encoding, if you can provide what that encoding is.  If you do not know the encoding of the file, then `CHCSVParser` can make a naïve guess.  `CHCSVParser` will try to guess the encoding of the file from among these options:

 - `NSMacOSRomanStringEncoding` (the default/fallback encoding)
 - `NSUTF8StringEncoding`
 - `NSUTF16BigEndianStringEncoding`
 - `NSUTF16LittleEndianStringEncoding`
 - `NSUTF32BigEndianStringEncoding`
 - `NSUTF32LittleEndianStringEncoding`
 
 
##Performance
`CHCSVParser` is conscious of low-memory environments, such as the iPhone or iPad.  It can safely parse very large CSV files, because it only loads portions of the file into memory at a single time.

##To Do
At some point, `CHCSVWriter` will support writing data directly to `NSOutputStream` instances.
 
##Credits & Contributors

`CHCSVParser` was written by [Dave DeLong][1].

`CHCSVParser` uses code to discover file encoding that was provided by [Rainer Brockerhoff][2].

  [1]: http://davedelong.com
  [2]: http://brockerhoff.net/
  
Thanks also to these people for suggestions and bug fixes to `CHCSVParser`:

- [Ben Barnett](https://github.com/benrb)
- [Aaron Wright](https://github.com/acwright)
- Gonzalo Castro
- Chris Gulley
  
##License

`CHCSVParser` is licensed under the MIT license, which is reproduced in its entirety here:


>Copyright (c) 2011 Dave DeLong
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
