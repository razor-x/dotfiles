function backward-word-or-atuin \
    --description 'Move the cursor back one work; if empty, open Atuin'

    if test -z (commandline)
        _atuin_search
    else
        commandline --function backward-word
    end
end
