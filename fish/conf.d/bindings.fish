fish_hybrid_key_bindings
bind --mode default vv edit_command_buffer

bind ctrl-p --mode insert up-or-search
bind ctrl-n --mode insert down-or-search
bind ctrl-e --mode insert end-of-line accept-autosuggestion
bind ctrl-a --mode insert beginning-of-line-or-history-pager
bind ctrl-f --mode insert forward-word
bind ctrl-r --mode insert backward-word

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
abbr d yazi

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

# Colorize help text using bat.
abbr -a --position anywhere -- --help '--help | bat -plhelp'

abbr rmrf rf -rf

abbr cljcli lein repl
abbr pycli bpython
abbr rbcli pry
abbr jscli node

abbr archrc cd "$ACONFMGR_CONFIG/.."
