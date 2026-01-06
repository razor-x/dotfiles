#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing c ==="

echo "-- compile: file --"
compile $dir/main.c
and $dir/main
and rm -f $dir/main

echo "-- format: file to stdout --"
format $dir/unformatted.c | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.c | format -e c

echo "-- lint: file (should fail) --"
lint $dir/fixable.c
or echo "lint failed as expected"

echo "-- lint: stdin (should fail) --"
cat $dir/fixable.c | lint -e c
or echo "stdin not supported as expected"
