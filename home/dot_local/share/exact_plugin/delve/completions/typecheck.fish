function __fish_complete_typecheck_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.c \
        $token*.go \
        $token*.ts \
        $token*.tsx \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_typecheck_extensions
    printf '%s\t%s\n' \
        c C \
        go Go \
        ts TypeScript \
        tsx 'TypeScript JSX'
end

complete \
    --command typecheck \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_typecheck_extensions)' \
    --description 'Explicitly set file extension'

complete \
    --command typecheck \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_typecheck_files)'

complete \
    --command typecheck \
    --condition '__fish_seen_argument --short e --long extension'
