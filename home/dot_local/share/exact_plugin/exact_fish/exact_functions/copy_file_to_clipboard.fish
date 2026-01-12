function copy_file_to_clipboard \
    --description 'Fuzzy-search and copy file contents to clipboard'

    set --function files $argv
    if test (count $files) -eq 0
        set --function files \
            (fzf --multi --preview 'bat --color=always --style=plain {}')
        or return
    end

    cat $files \
        | string collect \
        | fish_clipboard_copy
end
