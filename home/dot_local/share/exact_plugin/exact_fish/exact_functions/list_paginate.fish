function list_paginate \
    --wraps eza \
    --description 'List all files with pagination'

    if not set --query PAGER; or test -z "$PAGER"
        echo 'Cannot paginate: PAGER is not set.' >&2
        return 1
    end

    set --function cmd $PAGER
    eza --long --all --color=always $argv | $cmd
end
