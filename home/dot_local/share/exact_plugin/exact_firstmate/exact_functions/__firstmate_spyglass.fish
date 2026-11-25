function __firstmate_spyglass --argument-names anchor vessel --description 'Attach to the vessel tmux server read-only'
    test -n "$vessel"; or set vessel flagship
    if string match --quiet --regex '[/\n]|^\.{1,2}$' -- "$vessel"
        printf 'firstmate spyglass: invalid vessel name\n' >&2
        return 2
    end
    set anchor (__firstmate_find_anchor "$anchor")
    or begin
        printf 'firstmate spyglass: directory or ancestor .firstmate not found\n' >&2
        return 1
    end
    set --local socket "$anchor/.firstmate/$vessel/tmux/tmux-"(id -u)"/default"
    set --local candidates (command tmux -S "$socket" list-panes -a \
        -f '#{!=:#{pane_dead},1}' \
        -F '#{pane_id}	#{session_name}:#{window_name}.#{pane_index}  │  #{pane_current_command}  │  #{pane_current_path}')
    or return $status
    if not set --query candidates[1]
        printf 'firstmate spyglass: no live panes for %s\n' "$vessel" >&2
        return 1
    end
    set --local preview 'tmux -S '(string escape -- "$socket")' capture-pane -p -t {1} -S -100'
    set --local selected (printf '%s\n' $candidates | command fzf \
        --no-multi \
        --no-history \
        --delimiter=\t \
        --with-nth=2.. \
        --prompt='Spyglass> ' \
        --preview="$preview" \
        --preview-window='right,60%,wrap' \
        --bind='ctrl-/:toggle-preview')
    test -n "$selected"; or return 1
    contains -- "$selected" $candidates; or return 1
    set --local pane (string split --max 1 \t -- "$selected")[1]
    # Clear the caller's tmux context so this is a separate read-only client.
    command env -u TMUX tmux -S "$socket" attach-session -r -t "$pane"
end
