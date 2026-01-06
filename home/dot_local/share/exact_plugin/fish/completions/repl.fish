complete \
    --command repl \
    --no-files \
    --condition '__fish_is_first_arg' \
    --arguments 'fish js ts bash sh zsh' \
    --description 'Language extension'

complete \
    --command repl \
    --condition '__fish_is_first_arg' \
    --arguments '(__fish_complete_suffix .fish .js .ts .bash .sh .zsh)' \
    --description 'Source file'
