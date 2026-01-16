function execute-in-split \
    --description 'Executes the current commandline in a new split native to the current terminal emulator (if supported); closes split on exit'

    argparse 'before' -- $argv
    or return

    commandline --function expand-abbr
    set --function cmd (commandline)

    set --function location after
    if set --query _flag_before
        set --function location before
    end

    if set --query KITTY_PID; type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ launch --cwd=current --location=$location \
            fish --interactive --command $cmd
    else
        commandline --function execute
    end
end
