function git \
    --wraps git \
    --description 'Make git diff and show ignore whitespace'

    if contains -- "$argv[1]" diff show
        command git $argv[1] --ignore-all-space $argv[2..]
    else
        command git $argv
    end
end
