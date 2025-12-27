if status is-interactive
    # Ag
    abbr a rg
    abbr aa batgrep

    # dir
    # abbr d d

    # edit
    if set --query EDITOR
        abbr e $EDITOR
    end
    if set --query VISUAL
        abbr e $VISUAL
    end

    # list
    alias l 'eza -l'
    alias ll 'eza -1'
    alias la 'eza -la'
    alias ls 'eza'
    alias lsp list_paginate

    # eXtract
    abbr x ouch d

    # view
    abbr v bat -p --paging=always
    abbr vv prettybat -p --paging=always

    # Cat
    abbr c bat -pP

    # MultipleX
    abbr mx zellij

    # monitor
    abbr mon zenith

    abbr dl xh -d
    abbr dif delta

    abbr gg gitui
    abbr --erase gsd
    alias gsd git_find_replace
    alias gs git_idempotent_switch

    # Colorize help text using bat.
    # https://github.com/sharkdp/bat#highlighting---help-messages
    abbr --add --position anywhere -- --help '--help | bat -plhelp'

    abbr rmf rm -rf

    alias d yazi_change_cwd

    abbr cljrepl lein repl
    abbr pyrepl bpython
    abbr rbrepl pry

    abbr jsrepl node
    abbr fmtjs prettier --write --single-quote --jsx-single-quote --no-semi

    abbr npr npm run

    abbr md glow --tui

    abbr gfup git fetch --no-tags upstream
    abbr gfmk git fetch --no-tags makenew

    if set --query ACONFMGR_CONFIG
        abbr archrc cd "$ACONFMGR_CONFIG/.."
    end

    abbr dotfiles cd "(chezmoi source-path)"
    abbr dotap chezmoi update --apply --init
    abbr dotup chezmoi update --apply --init
    alias dotwatch 'watchexec --watch (chezmoi source-path) -- chezmoi apply --init'
    alias dotreset 'chezmoi state delete-bucket --bucket=scriptState;
        and chezmoi state delete-bucket --bucket=entryState;
        and chezmoi apply --init'

    # Use batpipe as the less preprocessor.
    if type --query batpipe
        eval (batpipe)
    end

    # User batman as the MANPAGER.
    if type --query batman
        batman --export-env | source
    end

    # Use zoxide.
    if type --query zoxide
        zoxide init --cmd j fish | source
    end

    alias now='date +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowutc='date --utc +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowz='date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ"'
    alias today='date --iso-8601=date'

    alias theme_kitty='kitten themes --reload-in=all'
    alias theme_fish='fish_config theme choose'

    if type --query mise
        mise activate fish | source
    end

    # TODO: Port more abbr and functions.
    # https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/archlinux/archlinux.plugin.zsh
    if type --query aura
        abbr pacman aura
        alias pacin arch_package_fzf_install
        alias pacrem arch_package_fzf_remove
        abbr pacmir aura -Syy
        abbr pacins aura -U
        abbr pacupg aura -Syu
        abbr paclean aura -Sc
        abbr aurin aura -A
        abbr aurupg aura -Au
        abbr mirrorupg systemctl restart reflector.service
    end

    alias srv caddy_file_server

    # Install Atuin shell plugin.
    if type --query atuin
        atuin init fish --disable-up-arrow --disable-ctrl-r | source
    end

    # Set fifc editor.
    set --export fifc_editor $VISUAL
end
