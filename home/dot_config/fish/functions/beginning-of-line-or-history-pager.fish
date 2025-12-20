function beginning-of-line-or-history-pager \
    --description 'Move the cursor to the beginning of the line; if empty, open the history pager'

    if test -z (commandline)
        commandline --function history-pager
    else
        commandline --function beginning-of-line
    end
end
