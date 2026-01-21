function __fish_complete_format_files
    set --function token \
        (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))

    for file in \
        $token*.bash \
        $token*.sh \
        $token*.zsh \
        $token*.c \
        $token*.clj \
        $token*.fish \
        $token*.go \
        $token*.js \
        $token*.jsx \
        $token*.ts \
        $token*.tsx \
        $token*.json \
        $token*.jsonc \
        $token*.html \
        $token*.css \
        $token*.graphql \
        $token*.md \
        $token*.yml \
        $token*.yaml \
        $token*.lua \
        $token*.py \
        $token*.rb \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

function __fish_complete_format_extensions
    printf '%s\t%s\n' \
        bash Bash \
        sh Shell \
        zsh Zsh \
        c C \
        clj Clojure \
        fish Fish \
        go Go \
        js JavaScript \
        jsx 'JavaScript JSX' \
        ts TypeScript \
        tsx 'TypeScript JSX' \
        json 'JSON' \
        jsonc 'JSON with Comments' \
        html 'HTML' \
        css 'CSS' \
        graphql 'GraphQL' \
        md 'Markdown' \
        yml 'YAML' \
        yaml 'YAML' \
        lua 'Lua' \
        py Python \
        rb Ruby
end

complete \
    --command format \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_format_extensions)' \
    --description 'Explicitly set file extension'

complete \
    --command format \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_format_files)' \

complete \
    --command format \
    --condition '__fish_seen_argument --short e --long extension'
