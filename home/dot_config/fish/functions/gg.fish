function gg
    git switch $argv[1] 2>/dev/null; or git switch -c $argv[1]
end
