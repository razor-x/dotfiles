#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing go ==="

echo "-- run: file --"
run $dir/main.go

echo "-- run: stdin (should fail) --"
cat $dir/main.go | run -e go
or echo "stdin not supported as expected"

echo "-- compile: file --"
compile $dir/main.go
and $dir/main
and rm -f $dir/main

echo "-- format: file to stdout --"
format $dir/unformatted.go | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.go | format -e go

echo "-- lint: file (should fail) --"
lint $dir/fixable.go
or echo "lint failed as expected"

echo "-- lint: valid file --"
lint $dir/main.go
and echo "lint passed"
