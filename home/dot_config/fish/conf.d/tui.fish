# Ag
abbr a rg
abbr aa batgrep

# dir
# abbr d d

# edit
abbr e $VISUAL

# list
functions --erase ll
functions --erase la
functions --erase ls
alias l 'eza -l'
alias ll 'eza -1'
alias la 'eza -la'
alias ls 'eza'
function lsp --description "List all files with pagination."
    set -l cmd (__fish_anypager)
    or return 1
    eza -la --color=always $argv | $cmd
end

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

# Colorize help text using bat.
abbr -a --position anywhere -- --help '--help | bat -plhelp'

abbr rmf rm -rf

abbr cljrepl lein repl
abbr pyrepl bpython
abbr rbrepl pry

abbr jsrepl node
abbr fmtjs prettier -w --single-quote --jsx-single-quote --no-semi

abbr archrc cd "$ACONFMGR_CONFIG/.."

abbr dotfiles cd "(chezmoi source-path)"
alias dotwatch "fd . (chezmoi source-path) -t file | entr chezmoi apply"

if status is-interactive
    # Use batpipe as the less preprocessor.
    eval (batpipe)

    # User batman as the MANPAGER.
    batman --export-env | source

    # Use zoxide.
    zoxide init --cmd j fish | source
end


alias now='date +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
alias nowutc='date --utc +"%Y-%m-%dT%H:%M:%S.%3N%:z"'
alias nowz='date --utc +"%Y-%m-%dT%H:%M:%S.%3NZ"'
alias today='date --iso-8601=date'
