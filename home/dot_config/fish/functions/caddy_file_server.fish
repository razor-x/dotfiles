function caddy_file_server \
    --argument-names port \
    --description 'Start a local Caddy file server'

    set --query port[1]
    or set port 8080

    echo ''
    echo "> http://localhost:$port"
    echo ''

    caddy file-server --listen :8080
end

