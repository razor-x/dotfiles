function git_find_replace \
    --wraps 'sd' \
    --description 'Find and replace with sd in all non-binary files tracked by git'

    git grep --null --full-name --files-with-matches '.' \
        | xargs --null --no-run-if-empty sd $argv
end
