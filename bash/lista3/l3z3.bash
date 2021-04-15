#!/bin/bash

for file in `svn list -R -r $1 $2@$1 | grep '[^\/]$'`; do
	svn cat -r $1 $2$file@$1 | tr -s ' ' '\n' | sort -u
done | sort | uniq -c
