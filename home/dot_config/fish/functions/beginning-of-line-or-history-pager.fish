function beginning-of-line-or-history-pager \
    --description 'Move the cursor to the beginning of the line; if empty, open the history pager'

    if test -z (commandline)
        commandline -f history-pager
    else
        commandline -f beginning-of-line
    end
end
