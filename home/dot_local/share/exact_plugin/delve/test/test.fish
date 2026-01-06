#!/usr/bin/env fish

set --local dir (path dirname (status filename))

for test in $dir/*/test.fish
    fish $test
    echo
end
