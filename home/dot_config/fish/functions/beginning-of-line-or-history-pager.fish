function beginning-of-line-or-history-pager \
    --description 'Move the cursor to the beginning of the line; if empty, open the history pager'

    if string length --quiet -- (commandline)
        commandline --function beginning-of-line
    else
        commandline --function history-pager
    end
end
