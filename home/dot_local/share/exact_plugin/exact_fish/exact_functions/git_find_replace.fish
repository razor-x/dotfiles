function git_find_replace \
    --wraps sd \
    --description 'Find and replace with sd in all non-binary files tracked by git'

    set --function root (git rev-parse --show-toplevel)
    set --function files (git grep --full-name --files-with-matches '.')
    sd $argv $root/$files
end
