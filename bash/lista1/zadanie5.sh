#!/bin/bash

for path in $(find $1 -type f -print); do
	sed -i 's/a/A/g' $path
done
