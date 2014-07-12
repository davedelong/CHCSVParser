//
//  UnitTestContent.h
//  CHCSVParser
//
//  Created by Dave DeLong on 5/5/13.
//
//

#define EMPTY @""
#define COMMA @","
#define SEMICOLON @";"
#define DOUBLEQUOTE @"\""
#define NEWLINE @"\n"
#define SPACE @" "
#define BACKSLASH @"\\"
#define OCTOTHORPE @"#"
#define EQUAL @"="

#define FIELD1 @"field1"
#define FIELD2 @"field2"
#define FIELD3 @"field3"
#define UTF8FIELD4 @"ḟīễłđ➃"

#define QUOTED_FIELD1 DOUBLEQUOTE FIELD1 DOUBLEQUOTE
#define QUOTED_FIELD2 DOUBLEQUOTE FIELD2 DOUBLEQUOTE
#define QUOTED_FIELD3 DOUBLEQUOTE FIELD3 DOUBLEQUOTE

#define MULTILINE_FIELD FIELD1 NEWLINE FIELD2