if status is-interactive
    # Ag
    abbr a rg
    abbr aa batgrep

    # dir
    # abbr d d

    # edit
    abbr e $VISUAL

    # list
    alias l 'eza -l'
    alias ll 'eza -1'
    alias la 'eza -la'
    alias ls 'eza'
    alias lsp list_paginate

    # eXtract
    abbr x ouch d

    # view
    abbr v bat -p
    abbr vv prettybat -p

    # MultipleX
    abbr mx zellij

    # monitor
    abbr mon zenith

    abbr dl xh -d
    abbr dif delta

    abbr gg gitui
    abbr gcln! git clean -fdx
    alias gs git_idempotent_switch

    # Colorize help text using bat.
    abbr -a --position anywhere -- --help '--help | bat -plhelp'

    abbr rmf rm -rf

    alias d yazi_change_cwd

    abbr cljrepl lein repl
    abbr pyrepl bpython
    abbr rbrepl pry

    abbr jsrepl node
    abbr fmtjs prettier -w --single-quote --jsx-single-quote --no-semi

    abbr archrc cd "$ACONFMGR_CONFIG/.."

    abbr dotfiles cd "(chezmoi source-path)"
    alias dotwatch dotfiles_watch_and_apply

    # Use batpipe as the less preprocessor.
    eval (batpipe)

    # User batman as the MANPAGER.
    batman --export-env | source

    # Use zoxide.
    zoxide init --cmd j fish | source

    alias now='date +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowutc='date --utc +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowz='date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ"'
    alias today='date --iso-8601=date'
end
