function caddy_file_server \
    --wraps 'caddy file-server' \
    --description 'Start a local Caddy file server'

    argparse 'listen=' -- $argv
    or return

    if set --query _flag_listen
        set --function port (string split ':' $_flag_listen)[-1]
    else
        set --function port 8080
        set --function _flag_listen ":$port"
    end

    echo ''
    echo "> http://localhost:$port"
    echo ''

    caddy file-server --listen $_flag_listen $argv
end

