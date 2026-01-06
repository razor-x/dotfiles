function __fish_complete_run_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in \
        $token*.fish \
        $token*.go \
        $token*.js \
        $token*.ts \
        $token*.bash \
        $token*.sh \
        $token*.zsh \
        $token*.py \
        $token*.rb \
        $token*.pl \
        $token*.lua \
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
        ts TypeScript \
        bash Bash \
        sh Shell \
        zsh Zsh \
        py Python \
        rb Ruby \
        pl Perl \
        lua Lua
end

complete \
    --command run \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments '(__fish_complete_run_extensions)'

complete \
    --command run \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_run_files)'

complete \
    --command run \
    --condition '__fish_seen_argument --short e --long extension'
