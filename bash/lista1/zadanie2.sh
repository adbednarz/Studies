#!/bin/bash

find $1 -type f -print0 | xargs -0 cat | tr ' ' '\n' | sort | uniq -c | grep -v -x -E '[[:blank:]]*[[0-9]+[[:blank:]]*'

