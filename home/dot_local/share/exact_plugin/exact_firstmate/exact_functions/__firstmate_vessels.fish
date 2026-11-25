function __firstmate_vessels \
    --description 'Complete locally registered vessels at the selected anchor'
    set --local tokens (commandline --tokens-expanded --current-process --cut-at-cursor)
    set --erase tokens[1]
    set --local subcommand launch
    if contains -- "$tokens[1]" launch spyglass aheadfull allstop sail scuttle
        set subcommand "$tokens[1]"
        set --erase tokens[1]
    end

    set --local anchor
    if set --query tokens[1]; and not string match --quiet -- '-*' "$tokens[1]"
        set anchor "$tokens[1]"
        if test "$subcommand" = spyglass
            set anchor (__firstmate_find_anchor "$anchor")
        end
    else
        set anchor (__firstmate_find_anchor "$PWD")
    end
    test -d "$anchor"; or return

    set --local core (__firstmate_core)
    test -x "$core/bin/fm-anchor.sh"; or return
    command "$core/bin/fm-anchor.sh" list --anchor "$anchor"
end
