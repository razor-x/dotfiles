function backward-word-or-atuin \
    --description 'Move the cursor back one work; if empty, open Atuin'

    if string length --quiet -- (commandline)
        commandline --function backward-word
    else
        _atuin_search
    end
end
