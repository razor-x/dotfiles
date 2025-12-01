function dotfiles_watch_and_apply --description "Watch and apply changes to dotfiles"
    fd . (chezmoi source-path) -t file | entr chezmoi apply
end
