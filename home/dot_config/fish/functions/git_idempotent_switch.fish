function git_idempotent_switch --description 'Switch to a Git branch, creating it first if needed'
    git switch $argv[1] 2>/dev/null
    or git switch -c $argv[1]
end
