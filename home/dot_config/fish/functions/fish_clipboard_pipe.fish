function fish_clipboard_pipe \
    --description 'Pipe the current command to the system clipboard'

    set cmd fish_clipboard_copy

    set pipe " | $cmd"
    if string match -rq -- ' \n\.$' "$(commandline -j; echo .)"
        set pipe "| $cmd"
    end
    fish_commandline_append $pipe
end
