#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing fish ==="

echo "-- run: file --"
run $dir/main.fish

echo "-- run: stdin --"
cat $dir/main.fish | run -e fish

echo "-- run: file with -e override --"
run -e fish $dir/main.fish

echo "-- format: file to stdout --"
format $dir/unformatted.fish | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.fish | format -e fish

echo "-- lint: file (should fail) --"
lint $dir/fixable.fish
or echo "lint failed as expected"

echo "-- lint: valid file --"
lint $dir/main.fish
and echo "lint passed"
