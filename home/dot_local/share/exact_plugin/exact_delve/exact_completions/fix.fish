function __fish_complete_fix_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.go \
        $token*.js \
        $token*.jsx \
        $token*.ts \
        $token*.tsx \
        $token*.css \
        $token*.py \
        $token*.rb \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_fix_extensions
    printf '%s\t%s\n' \
        go Go \
        js JavaScript \
        jsx 'JavaScript JSX' \
        ts TypeScript \
        tsx 'TypeScript JSX' \
        css CSS \
        py Python \
        rb Ruby
end

complete \
    --command fix \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_fix_extensions)' \
    --description 'Explicitly set file extension'

complete \
    --command fix \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_fix_files)'

complete \
    --command fix \
    --condition '__fish_seen_argument --short e --long extension'
