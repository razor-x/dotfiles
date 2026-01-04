#!/usr/bin/env fish

if test (count $argv) -eq 0
    echo 'Missing path to README.md as first argument.'
    return 1
end

set --local input (cat $argv[1] | string collect)
set --local input (string split --fields 1 --max 1 '<!-- end man page -->' $input)
set --local input (string split --fields 2 --max 1 '<!-- begin man page -->' $input)

string replace --all '### ' '# ' $input \
    | while read -l line
    if string match --quiet '# *' -- $line
        string upper $line
    else
        echo $line
    end
end \
    | pandoc --from markdown --to man
