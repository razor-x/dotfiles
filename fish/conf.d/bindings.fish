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
abbr av batgrep

# zoom
abbr z zoxide

# dir
abbr d yazi

# edit
abbr e $VISUAL

# list
abbr l ls -lh

# eXtract
abbr x ouch d

# view
abbr v bat -p

# MultipleX
abbr mx zellij

abbr rmrf rf -rf

abbr cljcli lein repl
abbr pycli bpython
abbr rbcli pry
abbr jscli node
