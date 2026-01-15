function git_wt_idempotent_switch \
    --wraps 'wt switch' \
    --description 'Switch to a Git worktree with worktrunk, creating it first if needed'

    wt switch $argv 2>/dev/null
    or wt switch --create $argv
end
