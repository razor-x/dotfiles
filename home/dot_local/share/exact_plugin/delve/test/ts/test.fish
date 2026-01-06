#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing ts ==="

echo "-- run: file --"
run $dir/main.ts

echo "-- run: stdin --"
cat $dir/main.ts | run -e ts

echo "-- run: file with -e override --"
run -e ts $dir/main.ts

echo "-- format: file to stdout --"
format $dir/unformatted.ts | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.ts | format -e ts

echo "-- lint: file (should fail) --"
lint $dir/fixable.ts
or echo "lint failed as expected"

echo "-- lint: stdin (should fail) --"
cat $dir/fixable.ts | lint -e ts
or echo "stdin not supported as expected"
