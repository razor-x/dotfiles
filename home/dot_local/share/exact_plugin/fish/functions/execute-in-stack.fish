function execute-in-stack \
    --description 'Executes the current commandline in stacked (fullscreen) layout native to the current terminal emulator (if supported); restores layout on exit'

    commandline --function expand-abbr
    set --function cmd (commandline)

    if set --query KITTY_PID; type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ goto-layout stack

        # Use script (instead of exec) which allocates a pty for interactive commands, e.g., git add --patch.
        # Pipe to /dev/null to discard the typescript recording file.
        script --quiet --command 'fish --interactive --command "'$cmd'"' /dev/null

        kitty @ last-used-layout
    else
        commandline --function execute
    end
end
