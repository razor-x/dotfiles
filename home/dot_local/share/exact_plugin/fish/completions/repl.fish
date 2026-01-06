function __fish_complete_repl_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in \
            $token*.fish \
            $token*.js \
            $token*.ts \
            $token*.bash \
            $token*.sh \
            $token*.zsh \
            $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_repl_extensions
    printf '%s\t%s\n' \
        fish Fish \
        js JavaScript \
        ts TypeScript \
        bash Bash \
        sh Shell \
        zsh Zsh
end

complete \
    --command repl \
    --no-files \
    --arguments '(__fish_complete_repl_extensions)'

complete \
    --command repl \
    --no-files \
    --arguments '(__fish_complete_repl_files)'
