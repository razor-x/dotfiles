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
abbr l eza -l
abbr la eza -la
abbr ls eza

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
