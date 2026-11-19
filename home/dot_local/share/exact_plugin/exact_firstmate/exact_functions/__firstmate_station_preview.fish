function __firstmate_station_preview --argument-names meta worktree \
    --description 'Preview a Firstmate task brief and working tree'
    set --local home (path dirname -- (path dirname -- "$meta"))
    set --local task (path change-extension '' -- (path basename -- "$meta"))
    printf '%s\n%s\n\n' "$task" "$worktree"
    command git --no-optional-locks -C "$worktree" status --short --branch
    printf '\n── Task brief ──\n'
    set --local brief "$home/data/$task/brief.md"
    if test -f "$brief"
        if command --query bat
            command bat --color=always --style=plain --paging=never \
                --line-range=:150 -- "$brief"
        else
            command head --lines=150 -- "$brief"
        end
    else
        printf 'No task brief available.\n'
    end
end
