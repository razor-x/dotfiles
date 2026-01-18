function serve \
    --wraps 'caddy file-server' \
    --description 'Start a local HTTP static file server'

    argparse 'listen=' -- $argv
    or return

    if set --query --function _flag_listen
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
