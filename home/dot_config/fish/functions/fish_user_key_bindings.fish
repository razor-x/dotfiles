fish_hybrid_key_bindings

function fish_user_key_bindings \
    --description 'Fish automatically executes this function after setting all preset bindings'

    fzf_configure_bindings \
        --directory='ctrl-;' \
        --git_log="ctrl-'" \
        --git_status='ctrl-g' \
        --history='' \
        --processes='ctrl-\\' \
        --variables='ctrl-.'

    # Erase all Alt bindings.
    bind \
        | grep alt- \
        | string replace -r '^bind\s+(.*?)(alt-\S+)\s.*' 'bind --erase $1$2' \
        | source

    # Erase conflicting navigation bindings.
    bind \
        | grep 'ctrl-[hjkl] ' \
        | string replace -r '^bind\s+(.*?)(ctrl-\S+)\s.*' 'bind --erase $1$2' \
        | source

    bind --mode default vv edit_command_buffer

    bind ctrl-p --mode insert up-or-search
    bind ctrl-n --mode insert down-or-search
    bind ctrl-e --mode insert end-of-line accept-autosuggestion
    bind ctrl-a --mode insert beginning-of-line-or-history-pager
    bind ctrl-f --mode insert forward-word
    bind ctrl-r --mode insert backward-word
    bind ctrl-b --mode insert backward-delete-char
    bind ctrl-y --mode insert backward-delete-char
    bind ctrl-o --mode insert forward-char
    bind ctrl-u --mode insert backward-char
    bind ctrl-q --mode insert fish_paginate

    bind ctrl-/ --mode insert __fish_whatis_current_token
    bind ctrl-/ --mode visual __fish_whatis_current_token
end

function beginning-of-line-or-history-pager \
    --description 'Move the cursor to the beginning of the line; if already there, open the history pager'

    if test -z (commandline)
        commandline -f history-pager
    else
        commandline -f beginning-of-line
    end
end
