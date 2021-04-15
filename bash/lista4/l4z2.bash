#!/bin/bash

x=$1;
url="$3"
dir=$(basename $url)
mkdir $dir
git init $dir

echo .git >> $dir/.gitignore
echo .gitignore >> $dir/.gitignore
echo .svn >> $dir/.gitignore

while [ $x -le $2 ] ; do
	svn checkout --depth infinity -r $x $url $dir
	comment=`svn propget svn:log --revprop -r $x $dir`
	git -C $dir add --all
	git -C $dir commit -m "$comment"
	x=$(($x + 1))
done
