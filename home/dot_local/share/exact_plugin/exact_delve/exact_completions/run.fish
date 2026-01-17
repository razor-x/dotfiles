function __fish_complete_run_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.fish \
        $token*.go \
        $token*.js \
        $token*.jsx \
        $token*.ts \
        $token*.tsx \
        $token*.py \
        $token*.bash \
        $token*.sh \
        $token*.zsh \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_run_extensions
    printf '%s\t%s\n' \
        fish Fish \
        go Go \
        js JavaScript \
        jsx 'JavaScript JSX' \
        ts TypeScript \
        tsx 'TypeScript JSX' \
        py Python \
        bash Bash \
        sh Shell \
        zsh Zsh
end

complete \
    --command run \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_run_extensions)' \
    --description 'Explicitly set file extension'

complete \
    --command run \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_run_files)'

complete \
    --command run \
    --condition '__fish_seen_argument --short e --long extension'
