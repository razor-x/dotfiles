function execute-in-tab \
    --description 'Executes the current commandline in a new tab native to the current terminal emulator (if supported); closes tab on exit'

    commandline --function expand-abbr
    set --function cmd (commandline)

    if set --query KITTY_PID; type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ launch --cwd=current --type=tab \
            fish --interactive --command $cmd
    else
        commandline --function execute
    end
end
