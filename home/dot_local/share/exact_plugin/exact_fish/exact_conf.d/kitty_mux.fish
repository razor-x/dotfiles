if status is-interactive;
    and set --query KITTY_WINDOW_ID;
    and not set --query SSH_CONNECTION;
    and not set --query ZELLIJ;
    and not set --query TMUX

    # @fish-lsp-disable-next-line 4004
    function __kitty_mux_start --on-event fish_preexec --argument-names commandline
        set --function mux_commands ssh tmux zellij
        set --function command_prefixes command exec

        set --function tokens (commandline --tokens-expanded --input "$commandline")
        while contains -- "$tokens[1]" $command_prefixes
            set --erase tokens[1]
        end

        set --local program (path basename -- "$tokens[1]")
        if contains -- "$program" $mux_commands
            printf '\e]1337;SetUserVar=IS_MUX=MQ==\a'
        else if test "$program" = firstmate; and test "$tokens[2]" = spyglass
            printf '\e]1337;SetUserVar=IS_MUX=MQ==\a'
        end
    end

    # @fish-lsp-disable-next-line 4004
    function __kitty_mux_end --on-event fish_postexec
        printf '\e]1337;SetUserVar=IS_MUX\a'
    end
end
