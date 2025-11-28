fish_hybrid_key_bindings
bind --mode default vv edit_command_buffer

# Unbind all alt bindings.
bind \
  | grep 'alt-' \
  | string replace -r '^bind\s+(.*?)(alt-\S+)\s.*' 'bind --erase $1$2' \
  | source

bind ctrl-p --mode insert up-or-search
bind ctrl-n --mode insert down-or-search
bind ctrl-e --mode insert end-of-line accept-autosuggestion
bind ctrl-a --mode insert beginning-of-line-or-history-pager
bind ctrl-f --mode insert forward-word
bind ctrl-r --mode insert backward-word
bind ctrl-o --mode insert forward-char
bind ctrl-b --mode insert backward-char

function beginning-of-line-or-history-pager
  if test -z (commandline)
    commandline -f history-pager
  else
    commandline -f beginning-of-line
  end
end

# Ag
abbr a rg
abbr aa batgrep

# dir
# abbr d d

# edit
abbr e $VISUAL

# list
abbr l eza

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
