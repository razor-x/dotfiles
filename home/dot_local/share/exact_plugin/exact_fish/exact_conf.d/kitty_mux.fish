if not status is-interactive;
    or not set --query KITTY_WINDOW_ID;
    or set --query SSH_CONNECTION;
    or set --query ZELLIJ;
    or set --query TMUX
    return
end

# @fish-lsp-disable-next-line 4004
function __kitty_mux_start --on-event fish_preexec --argument-names commandline
    set --function mux_commands ssh tmux zellij
    set --function command_prefixes command exec

    set --function tokens (commandline --tokens-expanded --input "$commandline")
    while contains -- "$tokens[1]" $command_prefixes
        set --erase tokens[1]
    end

    if contains -- (path basename -- "$tokens[1]") $mux_commands
        printf '\e]1337;SetUserVar=IS_MUX=MQ==\a'
    end
end

# @fish-lsp-disable-next-line 4004
function __kitty_mux_end --on-event fish_postexec
    printf '\e]1337;SetUserVar=IS_MUX\a'
end
