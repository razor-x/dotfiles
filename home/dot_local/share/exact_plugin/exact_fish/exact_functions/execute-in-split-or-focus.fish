function execute-in-split-or-focus \
    --description 'Executes the --command in a new split native to the current terminal emulator (if supported); closes split on exit; focus window if already open'

    argparse 'before' -- $argv
    or return

    set --function cmd $argv[1]

    if test -z "$cmd"
        return 1
    end

    if set --query KITTY_PID; and type --query kitty; and type --query jq
        set --function window_id (kitty @ ls | jq --raw-output --arg cmd "$cmd" '
            [.[] | select(.is_active)
                | .tabs[] | select(.is_active)
                | .windows[]
                | select(any(.foreground_processes[].cmdline[0]?; . == $cmd))
                | .id][0] // empty
        ')

        if test -n "$window_id"
            commandline --replace ''
            kitty @ focus-window --match id:$window_id
            return
        end
    end

    set --function args $argv
    if set --query _flag_before
        set --prepend args --before
    end

    execute-in-split $args
end
