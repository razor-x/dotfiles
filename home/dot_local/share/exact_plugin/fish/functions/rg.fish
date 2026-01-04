function rg \
    --wraps rg \
    --description 'Wrap ripgrep to search hidden files when inside a git repository'

    if git rev-parse --is-inside-work-tree &>/dev/null
        command rg --hidden $argv
    else
        command rg $argv
    end
end
