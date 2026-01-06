function __fish_complete_lint_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in $token*.{fish,go,js,ts,tsx,bash,sh,zsh} $token*/
        if test -e $file
            echo $file
        end
    end
end

complete \
    --command lint \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments 'fish go js ts tsx bash sh zsh' \
    --description 'Syntax'

complete \
    --command lint \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_lint_files)'

complete \
    --command lint \
    --condition '__fish_seen_argument --short e --long extension'
