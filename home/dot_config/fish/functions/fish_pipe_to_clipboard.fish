function fish_pipe_to_clipboard \
    --description 'Pipe the current command into the system clipboard'

    set cmd fish_clipboard_copy

    set pipe " | $cmd"
    if string match --regex --quiet -- ' \n\.$' "(commandline --current-job; echo .)"
        set pipe "| $cmd"
    end
    fish_commandline_append $pipe
end
