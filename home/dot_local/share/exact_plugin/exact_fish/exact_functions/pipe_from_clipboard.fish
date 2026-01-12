function pipe_from_clipboard \
    --description 'Pipe the system clipboard into the current command'

    set --function cmd fish_clipboard_paste

    set --function prefix "$cmd |"
    fish_commandline_prepend $prefix
end
