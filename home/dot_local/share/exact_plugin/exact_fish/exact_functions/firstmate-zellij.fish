function firstmate-zellij \
    --wraps zellij \
    --description 'Run Zellij in FirstMate isolated environment'

    set --function data_home $XDG_DATA_HOME
    if test -z "$data_home"
        set data_home "$HOME/.local/share"
    end
    set --function firstmate_home "$data_home/firstmate/.tools/home"

    if not set --query ZELLIJ_CONFIG_DIR
        set --function --export ZELLIJ_CONFIG_DIR "$firstmate_home/zellij/config"
    end
    if not set --query ZELLIJ_SOCKET_DIR
        set --function --export ZELLIJ_SOCKET_DIR "$firstmate_home/zellij/socket"
    end

    command zellij $argv
end
