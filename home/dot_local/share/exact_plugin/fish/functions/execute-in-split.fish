function execute-in-split \
    --description 'Executes the current commandline in a new split native to the current terminal emulator (if supported)'

    commandline --function expand-abbr
    set cmd (commandline)

    if type --query kitty; and test -n "$cmd"
        commandline --replace ''

        kitty @ launch --cwd=current --location=hsplit \
            fish --interactive --command $cmd
    else
        commandline --function execute
    end
end
