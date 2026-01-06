function git_idempotent_switch \
    --wraps 'git switch' \
    --description 'Switch to a Git branch, creating it first if needed'

    git switch $argv 2>/dev/null
    or git switch --create $argv
end
