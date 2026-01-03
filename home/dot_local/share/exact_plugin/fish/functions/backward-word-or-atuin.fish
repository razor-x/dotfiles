function backward-word-or-atuin \
    --description 'Move one word to the left; if empty, open Atuin'

    if string length --quiet -- (commandline)
        commandline --function backward-word
    else
        _atuin_search
    end
end
