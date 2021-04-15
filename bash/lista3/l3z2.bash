#!/bin/bash

for file in `svn list -R -r $1 $2@$1 | grep '[^\/]$'`; do
	svn cat -r $1 $2$file@$1
done | tr -s ' ' '\n' | sort | uniq -c 

# -r revision
# -R recursion
# -s replaces a sequence of repeated occurrences with the character
