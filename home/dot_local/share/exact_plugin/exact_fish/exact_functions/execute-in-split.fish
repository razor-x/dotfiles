function execute-in-split \
    --description 'Executes the current commandline in a new split native to the current terminal emulator (if supported); closes split on exit'

    argparse 'before' -- $argv
    or return

    set --function cmd $argv
    if test -z "$cmd"
        commandline --function expand-abbr
        set --function cmd (commandline)
    end

    set --function location after
    if set --query _flag_before
        set --function location before
    end

    if set --query KITTY_PID; type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ launch --cwd=current --location=$location \
            fish --interactive --command $cmd
    else
        commandline --replace " $cmd"
        commandline --function execute
    end
end
