function zellij_scrollback \
    --description 'Save the Zellij scrollback and view it'

    set zellij_dump '/tmp/zellij_scrollback.dump.txt'

    if not test -f $zellij_dump
        echo 'Already saved and viewed the last dump, press Ctrl-C to close...'
        return 1
    end

    set now (date +"%Y-%m-%dT%H:%M:%S.%3N%:z")
    set zellij_scrollback "$HOME/scrollback.$now.txt"
    mv $zellij_dump $zellij_scrollback

    # Set the scrollback pager to use less -r to render Nerd Font symbols.
    # The -r option cannot be set in a LESS environment variable.
    less -r +G --chop-long-lines $zellij_scrollback

    echo $zellij_scrollback
end
