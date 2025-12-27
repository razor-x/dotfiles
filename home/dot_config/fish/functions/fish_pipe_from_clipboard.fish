function fish_pipe_from_clipboard \
    --description 'Pipe the system clipboard into the current command'

    set cmd fish_clipboard_paste

    set prefix "$cmd |"
    fish_commandline_prepend $prefix
end
