#!/bin/bash

for path in $(find $1 -type f -print); do
	while read line; do
    		if [ "$line" != " " ]; then
    			for word in $(echo $line | tr ' ' '\n' | sort | uniq -d); do
    				echo "$path"
    				echo "$word"
    				echo "$line"
    			done
    		fi
	done <$path
done
