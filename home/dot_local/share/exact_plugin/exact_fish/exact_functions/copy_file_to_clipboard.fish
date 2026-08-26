function copy_file_to_clipboard \
    --description 'Copy a file, or fuzzy-select one below the path at the cursor'

    set --function target (commandline --current-token | string unescape)
    set target (string replace --regex '^~(?=/|$)' $HOME -- $target)
    if test -z "$target"
        set target .
    end
    set target (path resolve $target)

    if path is -d $target
        set --function files \
            (fd --type file --hidden --exclude .git . $target | fzf --multi --preview 'bat --color=always --style=plain {}')
        or return
    else if path is -f $target
        set --function files $target
    else
        return
    end

    cat -- $files \
        | string collect \
        | fish_clipboard_copy
    and history append (string join ' ' 'cat --' (string escape -- $files) '|' fish_clipboard_copy)
    and commandline --replace ''
end
