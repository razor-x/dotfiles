#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing js ==="

echo "-- run: file --"
run $dir/main.js

echo "-- run: stdin --"
cat $dir/main.js | run -e js

echo "-- run: file with -e override --"
run -e js $dir/main.js

echo "-- format: file to stdout --"
format $dir/unformatted.js | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.js | format -e js

echo "-- lint: file (should fail) --"
lint $dir/fixable.js
or echo "lint failed as expected"

echo "-- lint: stdin --"
cat $dir/fixable.js | lint -e js
or echo "lint failed as expected"
