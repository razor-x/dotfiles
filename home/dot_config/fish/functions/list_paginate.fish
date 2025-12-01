function list_paginate \
    --description 'List all files with pagination'

    set -l cmd $PAGER
    or return 1
    eza -la --color=always $argv | $cmd
end
