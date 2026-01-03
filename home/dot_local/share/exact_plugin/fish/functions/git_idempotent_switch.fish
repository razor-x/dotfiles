function git_idempotent_switch \
    --argument-names branch \
    --wraps 'git switch' \
    --description 'Switch to a Git branch, creating it first if needed'

    git switch $branch 2>/dev/null
    or git switch --create $branch
end
