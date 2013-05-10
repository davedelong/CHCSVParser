#!/bin/sh

#  rts.sh
#  CHCSVParser
#
#  Created by Malte Tancred on 2013-05-10.
#

export PATH="$PATH":"$BUILT_PRODUCTS_DIR"
exec 2>&1

echo '---test empty'
parserlogger ''
echo $?

echo '---test one field'
parserlogger 'field'
echo $?

echo '---test two fields'
parserlogger 'field1,field2'
echo $?
