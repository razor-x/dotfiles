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

echo "-- format: file in-place --"
cp $dir/unformatted.go $dir/format.tmp.go
format $dir/format.tmp.go
cat $dir/format.tmp.go
rm $dir/format.tmp.go

echo "-- lint: file (should fail) --"
lint $dir/fixable.go
or echo "lint failed as expected"

echo "-- lint: valid file --"
lint $dir/main.go
and echo "lint passed"

echo "-- lint: --fix --"
cp $dir/fixable.go $dir/fix.tmp.go
lint --fix $dir/fix.tmp.go
and echo "lint --fix succeeded"
rm -f $dir/fix.tmp.go
