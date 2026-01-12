function backward-kill-word-or-navi \
    --description 'Move the word to the left of the cursor to the killring; if empty, open navi'

    if string length --quiet -- (commandline)
        commandline --function backward-kill-word
    else
        _navi_smart_replace
    end
end
