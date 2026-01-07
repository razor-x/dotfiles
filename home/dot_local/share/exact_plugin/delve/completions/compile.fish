function __fish_complete_compile_files
    set --local token (string replace --regex '\.$' '' -- (commandline --cut-at-cursor --current-token))
    for file in \
        $token*.c \
        $token*.go \
        $token*.js \
        $token*.jsx \
        $token*.ts \
        $token*.tsx \
        $token*/
        if test -e $file
            echo $file
        end
    end
end

complete \
    --command compile \
    --no-files \
    --arguments '(__fish_complete_compile_files)'
