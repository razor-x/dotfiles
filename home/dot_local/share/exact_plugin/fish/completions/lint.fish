function __fish_complete_lint_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in \
        $token*.fish \
        $token*.go \
        $token*.js \
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

function __fish_complete_lint_extensions
    printf '%s\t%s\n' \
        fish Fish \
        go Go \
        js JavaScript \
        ts TypeScript \
        tsx 'TypeScript JSX' \
        bash Bash \
        sh Shell \
        zsh Zsh
end

complete \
    --command lint \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_lint_extensions)'

complete \
    --command lint \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_lint_files)'

complete \
    --command lint \
    --condition '__fish_seen_argument --short e --long extension'
