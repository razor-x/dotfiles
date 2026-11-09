function firstmate-zellij \
    --wraps zellij \
    --description 'Run Zellij in FirstMate isolated environment'

    if not set --query XDG_STATE_HOME; or test -z "$XDG_STATE_HOME"
        echo 'Cannot run FirstMate Zellij: XDG_STATE_HOME is not set.' >&2
        return 1
    end

    set --function firstmate_home "$XDG_STATE_HOME/firstmate"

    if not set --query ZELLIJ_SOCKET_DIR
        set --function --export ZELLIJ_SOCKET_DIR "$firstmate_home/zellij/socket"
    end

    command zellij $argv
end
