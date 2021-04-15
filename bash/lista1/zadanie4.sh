#!/bin/bash

my_array_w=($(find $1 -type f -print0 | xargs -0 cat | tr ' ' '\n' | sort -u))

for word in ${my_array_w[*]}; do
	echo $word
	for path in $(find $1 -type f -print); do
		
		if cat $path | grep -we $word &> /dev/null
		then
			echo "$path"
			cat $path | grep -we $word
		fi
	done
	echo ""
done
