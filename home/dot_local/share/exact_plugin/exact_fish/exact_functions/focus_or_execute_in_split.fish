function focus_or_execute_in_split \
    --description 'Focuses a running command in current kitty tab or opens a new split'

    argparse 'before' 'command=' -- $argv
    or return

    set --function cmd $_flag_command

    if test -z "$cmd"
        echo "focus_or_execute_in_split: missing required option --command"
        return 1
    end

    if set --query KITTY_PID; and type --query kitty; and type --query jq
        set --function window_id (kitty @ ls | jq --raw-output --arg cmd "$cmd" '
            [.[] | select(.is_active)
                | .tabs[] | select(.is_active)
                | .windows[]
                | select([.foreground_processes[].cmdline[]?] | index($cmd))
                | .id][0] // empty
        ')

        if test -n "$window_id"
            commandline --replace ''
            kitty @ focus-window --match id:$window_id
            return
        end
    end

    commandline --replace " $cmd"
    execute-in-split
end
