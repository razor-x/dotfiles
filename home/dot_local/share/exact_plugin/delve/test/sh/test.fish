#!/usr/bin/env fish

set --local dir (path dirname (status filename))

echo "=== Testing sh ==="

echo "-- run: file --"
run $dir/main.sh

echo "-- run: stdin --"
cat $dir/main.sh | run -e sh

echo "-- run: file with -e override --"
run -e sh $dir/main.sh

echo "-- format: file to stdout --"
format $dir/unformatted.sh | cat

echo "-- format: stdin to stdout --"
cat $dir/unformatted.sh | format -e sh

echo "-- format: file in-place --"
cp $dir/unformatted.sh $dir/format.tmp.sh
format $dir/format.tmp.sh
cat $dir/format.tmp.sh
rm $dir/format.tmp.sh

echo "-- lint: file (should fail) --"
lint $dir/fixable.sh
or echo "lint failed as expected"

echo "-- lint: stdin (should fail) --"
cat $dir/fixable.sh | lint -e sh
or echo "stdin not supported as expected"

echo "-- lint: --fix not supported --"
lint --fix $dir/fixable.sh
or echo "lint --fix not supported as expected"
