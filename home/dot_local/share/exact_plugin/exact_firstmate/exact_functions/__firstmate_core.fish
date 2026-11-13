function __firstmate_core --description 'Locate the installed Firstmate core'
    set --local data_home "$HOME/.local/share"
    if set --query XDG_DATA_HOME[1]; and test -n "$XDG_DATA_HOME"
        set data_home "$XDG_DATA_HOME"
    end
    printf '%s/firstmate\n' "$data_home"
end
