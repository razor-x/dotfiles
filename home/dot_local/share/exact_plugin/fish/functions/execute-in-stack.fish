function execute-in-stack \
    --description 'Executes the current commandline in stacked (fullscreen) layout, restores layout on exit'

    commandline --function expand-abbr
    set --function cmd (commandline)

    if type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ goto-layout stack
        eval $cmd
        kitty @ last-used-layout
    else
        commandline --function execute
    end
end
