function __fish_complete_format_files
    set --local token (commandline --cut-at-cursor --current-token)
    for file in $token*.{fish,go,js,jsx,ts,tsx,bash,sh,zsh} $token*/
        if test -e $file
            echo $file
        end
    end
end

complete \
    --command format \
    --short-option e \
    --long-option extension \
    --exclusive \
    --arguments 'fish go js jsx ts tsx bash sh zsh' \
    --description 'Syntax'

complete \
    --command format \
    --no-files \
    --condition 'not __fish_seen_argument --short e --long extension' \
    --arguments '(__fish_complete_format_files)'

complete \
    --command format \
    --condition '__fish_seen_argument --short e --long extension'
