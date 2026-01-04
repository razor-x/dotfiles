function pipe_to_clipboard \
    --description 'Pipe the current command into the system clipboard'

    set --function cmd fish_clipboard_copy

    set --function pipe " | $cmd"
    if string match --regex --quiet -- ' \n\.$' "(commandline --current-job; echo .)"
        set --function pipe "| $cmd"
    end
    fish_commandline_append $pipe
end
