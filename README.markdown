#CHCSVParser

CHCSVParser is a parser for CSV files written in Objective-C.

##Supported Platforms

- Mac OS X 10.5+
- iOS 3+

##Usage

To use CHCSVParser, you must include at least `CHCSVParser.h` and `CHCSVParser.m` into your project.  If you'd like to use some convenience methods on `NSArray`, you may also include `NSArray+CHCSVAdditions.*` as well.

CHCSVParser relies on knowing the encoding of the CSV file.  It should work with pretty much any kind of file encoding, if you can provide what that encoding is.  If you do not know the encoding of the file, then CHCSVParser can make a naïve guess.  CHCSVParser will try to guess the encoding of the file from among these options:

 - NSUTF8StringEncoding (the default/fallback encoding)
 - NSUTF16BigEndianStringEncoding
 - NSUTF16LittleEndianStringEncoding
 - NSUTF32BigEndianStringEncoding
 - NSUTF32LittleEndianStringEncoding
 
##Credits

CHCSVParser was written by [Dave DeLong][1].

  [1]: http://davedelong.com