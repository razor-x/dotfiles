fish_hybrid_key_bindings
bind --mode default vv edit_command_buffer

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

abbr e $VISUAL
abbr d yazi
abbr l ls -lh

abbr cljcli lein repl
abbr pycli bpython
abbr rbcli pry
abbr jscli node
