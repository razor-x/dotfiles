function zellij_scrollback \
    --description 'Save the Zellij scrollback and view it.'

    set zellij_scrollback "$HOME/scrollback.$(now).txt"
    mv /tmp/zellij_scrollback.dump.txt $zellij_scrollback
    bat -p $zellij_scrollback
    echo $zellij_scrollback
end
