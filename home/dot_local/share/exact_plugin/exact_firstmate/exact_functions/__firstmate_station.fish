function __firstmate_station --description 'Pick a Firstmate worktree at the current anchor'
    set --local anchor "$PWD"
    if set --query argv[1]; and test -d "$argv[1]"
        set anchor (path resolve -- "$argv[1]")
        set --erase argv[1]
    end
    while not test -d "$anchor/.firstmate"
        if test "$anchor" = /
            printf '%s%s\n' \
                'Usage: firstmate station [DIRECTORY] [QUERY ...] ' \
                '(no ancestor contains .firstmate)' >&2
            return 1
        end
        set anchor (path dirname -- "$anchor")
    end
    set --local candidates
    set --local repo_width 0
    set --local station_width 0
    for meta in "$anchor"/.firstmate/*/state/*.meta
        set --local worktree
        set --local branch
        set --local remote
        while read --local line
            switch "$line"
                case 'worktree=*'
                    set worktree (string sub --start 10 -- "$line")
                case 'branch=*'
                    set branch (string sub --start 8 -- "$line")
                case 'remote=*'
                    set remote 1
            end
        end <"$meta"
        test -z "$remote"; or continue
        test -d "$worktree"; or continue
        command git -C "$worktree" rev-parse --is-inside-work-tree >/dev/null 2>&1; or continue
        set --local vessel (path basename -- (path dirname -- (path dirname -- "$meta")))
        set --local task (path change-extension '' -- (path basename -- "$meta"))
        set --local git_common_dir (command git -C "$worktree" rev-parse \
            --path-format=absolute --git-common-dir)
        or continue
        set --local repo (path basename -- (path dirname -- "$git_common_dir"))
        set repo_width (math "max($repo_width, "(string length -- "$repo")")")
        set station_width (math "max($station_width, "(string length -- "$vessel/$task")")")
        set --append candidates (printf '%s\t%s\t%s\t%s/%s\t%s' \
            "$worktree" "$branch" "$meta" "$vessel" "$task" "$repo")
    end
    if not set --query candidates[1]
        printf 'firstmate station: no local worktrees found\n' >&2
        return 1
    end
    for index in (seq (count $candidates))
        set --local fields (string split \t -- "$candidates[$index]")
        set --local repo_label (string pad --right --width "$repo_width" -- "$fields[5]")
        set --local station_label (string pad --right --width "$station_width" -- "$fields[4]")
        set candidates[$index] (printf '%s\t%s  │  %s  │  %s' \
            "$candidates[$index]" "$repo_label" "$station_label" "$fields[2]")
    end
    set --local query (string join ' ' -- $argv)
    set --local preview_file (status dirname)/__firstmate_station_preview.fish
    set --local preview_code \
        "source "(string escape -- "$preview_file")'; __firstmate_station_preview $argv'
    set --local preview \
        'fish --no-config --command '(string escape -- "$preview_code")' -- {3} {1}'
    set --local selected (printf '%s\n' $candidates | command fzf \
        --no-multi \
        --no-history \
        --delimiter=\t \
        --with-nth=6 \
        --prompt='Firstmate> ' \
        --query="$query" \
        --preview="$preview" \
        --preview-window='right,60%,wrap' \
        --bind='ctrl-/:toggle-preview')
    test -n "$selected"; or return 1
    contains -- "$selected" $candidates; or return 1
    set --local target (string split --max 1 \t -- "$selected")[1]
    # zoxide checks this exclusion when its PWD hook runs.
    set --local --export _ZO_EXCLUDE_DIRS '*'
    builtin cd -- "$target"
end
