function __fish_complete_repl_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.fish \
        $token*.clj \
        $token*.js \
        $token*.ts \
        $token*.lua \
        $token*.php \
        $token*.py \
        $token*.rb \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_repl_extensions
    printf '%s\t%s\n' \
        bash Bash \
        sh Shell \
        zsh Zsh \
        fish Fish \
        clj Clojure \
        js JavaScript \
        ts TypeScript \
        lua Lua \
        php PHP \
        py Python \
        rb Ruby
end

complete \
    --command repl \
    --no-files \
    --arguments '(__fish_complete_repl_extensions)'

complete \
    --command repl \
    --no-files \
    --arguments '(__fish_complete_repl_files)'
