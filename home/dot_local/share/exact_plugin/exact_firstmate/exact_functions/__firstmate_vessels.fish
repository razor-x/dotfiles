function __firstmate_vessels --description 'Complete locally registered vessels at the selected anchor'
    set --local tokens (commandline --tokens-expanded --current-process --cut-at-cursor)
    set --query tokens[2]; or return
    test -d "$tokens[2]"; or return
    set --local core (__firstmate_core)
    test -x "$core/bin/fm-anchor.sh"; or return
    command "$core/bin/fm-anchor.sh" list --anchor "$tokens[2]"
end
