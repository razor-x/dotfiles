function dotfiles_watch_and_apply \
    --description "Watch and apply changes to dotfiles"

    set src (chezmoi source-path)
    echo "Watching $src for changes..."
    while sleep 0.1
        fd . $src -t file | entr -d chezmoi apply
        or break
        echo "File added to $src..."
    end
end
