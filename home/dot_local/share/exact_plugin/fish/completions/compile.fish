function __fish_complete_compile_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in \
        $token*.go \
        $token*.c \
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
