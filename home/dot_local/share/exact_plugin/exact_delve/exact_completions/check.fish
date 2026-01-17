function __fish_complete_check_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.c \
        $token*.go \
        $token*.ts \
        $token*.tsx \
        $token*.py \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_check_extensions
    printf '%s\t%s\n' \
        c C \
        go Go \
        ts TypeScript \
        tsx 'TypeScript JSX' \
        py Python
end

complete \
    --command check \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_check_extensions)' \
    --description 'Explicitly set file extension'

complete \
    --command check \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_check_files)'

complete \
    --command check \
    --condition '__fish_seen_argument --short e --long extension'
