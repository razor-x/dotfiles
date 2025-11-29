function zellij_scrollback \
    --description 'Save the Zellij scrollback and view it.'

    set zellij_dump "/tmp/zellij_scrollback.dump.txt"

    if not test -f $zellij_dump
        echo "Already saved and viewed the last dump, press Ctrl-C to close..."
        return 1
    end

    set zellij_scrollback "$HOME/scrollback.$(now).txt"
    mv $zellij_dump $zellij_scrollback
    bat -p $zellij_scrollback
    echo $zellij_scrollback
end
