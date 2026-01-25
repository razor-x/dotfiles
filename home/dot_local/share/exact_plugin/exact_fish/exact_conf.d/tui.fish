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
    alias ls eza
    alias lsp list_paginate

    # eXtract
    abbr x ouch d

    # view
    abbr v bat
    # TODO: Abbr or alias once format can handle read from file to stdout
    # abbr vv format foo.ext | bat
    abbr vv prettybat

    # find
    abbr f fd
    # TODO: make abbv work like this
    # abbr ff fd … -X bat

    # Cat
    abbr c bat -pP

    # MultipleX
    abbr mx zellij

    # monitor
    abbr mon zenith

    abbr dl xh -d
    abbr dif delta

    abbr gg gitui
    abbr gdpr 'git diff (git merge-base main HEAD)'
    abbr grm! git rm -rf
    abbr gstaa git stash apply
    abbr --erase gsd
    alias gsd git_find_replace
    alias gs git_idempotent_switch
    abbr gw wt
    alias gws git_wt_idempotent_switch

    # Colorize help text using bat.
    # https://github.com/sharkdp/bat#highlighting---help-messages
    abbr --add --position anywhere -- --help '--help | bat -plhelp'

    abbr rmf rm -rf

    alias d yazi_change_cwd

    abbr npr npm run

    abbr md glow --tui

    abbr m mise
    abbr mm just

    abbr gfup git fetch --no-tags upstream
    abbr gfmk git fetch --no-tags makenew

    if set --query ACONFMGR_CONFIG
        abbr archrc cd "$ACONFMGR_CONFIG/.."
    end

    abbr dotfiles cd "(chezmoi source-path)"
    alias dotupg 'chezmoi update --apply --init'

    alias now='date +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowutc='date --utc +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
    alias nowz='date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ"'
    alias today='date --iso-8601=date'

    alias theme_kitty='kitten themes --reload-in=all'
    alias theme_fish='fish_config theme choose'

    # TODO: Port more abbr and functions.
    # https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/archlinux/archlinux.plugin.zsh
    if type --query aura
        abbr pacman aura
        alias pacin arch_package_fzf_install
        alias pacrem arch_package_fzf_remove
        alias pacdelta 'DIFFPROG=delta pacdiff --sudo'
        abbr pacmir aura -Syy
        abbr pacins aura -U
        abbr pacupg aura -Syu
        abbr paclean aura -Sc
        abbr aurin aura -A
        abbr aurupg aura -Au
        abbr mirrorupg systemctl restart reflector.service
    end

    abbr unfaillock faillock --user $USER --reset

    alias srv serve

    abbr o opencode

    # Set fifc editor.
    set --export fifc_editor $VISUAL
end
