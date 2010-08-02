#CHCSVParser

CHCSVParser is an Objective-C parser for CSV files.

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
 
CHCSVParser is conscious of low-memory environments, such as the iPhone or iPad.  It can safely parse very large CSV files, because it only loads portions of the file into memory at a single time.  For example, CHCSVParser can parse a 4 million line CSV file (over 300MB on disk) in under one second while only consuming about 75K of active memory.
 
##Credits

CHCSVParser was written by [Dave DeLong][1].

CHCSVParser uses code to discover file encoding that was provided by [Rainer Brockerhoff][2].

  [1]: http://davedelong.com
  [2]: http://brockerhoff.net/