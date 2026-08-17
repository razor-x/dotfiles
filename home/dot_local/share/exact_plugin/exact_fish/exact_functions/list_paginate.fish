function list_paginate \
    --wraps eza \
    --description 'List all files with pagination'

    set --function cmd $PAGER
    or return 1
    eza --long --all --color=always $argv | $cmd
end
