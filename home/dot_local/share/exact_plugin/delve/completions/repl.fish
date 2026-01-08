function __fish_complete_repl_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.fish \
        $token*.js \
        $token*.jsx \
        $token*.ts \
        $token*.tsx \
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
        jsx 'JavaScript JSX' \
        ts TypeScript \
        tsx 'TypeScript JSX' \
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
