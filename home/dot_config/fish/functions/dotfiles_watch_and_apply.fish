function dotfiles_watch_and_apply \
    --description "Watch and apply changes to dotfiles"

    set src (chezmoi source-path)
    echo "Watching $src for changes..."

    # All attempts to properly handle SIGINT via entr have failed.
    # Provide a 2 second window after entr exits for a second Ctrl-C
    # to exit the function.
    while sleep 2
        fd . $src -t file | entr -d chezmoi apply
        echo "File added to $src..."
    end
end
