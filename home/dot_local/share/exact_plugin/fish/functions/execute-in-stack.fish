function execute-in-stack \
    --description 'Executes the current commandline in stacked (fullscreen) layout native to the current terminal emulator (if supported); restores layout on exit'

    commandline --function expand-abbr
    set --function cmd (commandline)

    if set --query KITTY_PID; type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ goto-layout stack
        fish --interactive --command $cmd
        kitty @ last-used-layout
    else
        commandline --function execute
    end
end
