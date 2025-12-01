function dotfiles_watch_and_apply \
    --description "Watch and apply changes to dotfiles"

    while sleep 0.1
        fd . (chezmoi source-path) -t file | entr -d chezmoi apply
    end
end
