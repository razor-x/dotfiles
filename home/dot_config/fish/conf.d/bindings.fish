fish_hybrid_key_bindings
bind --mode default vv edit_command_buffer

bind \ce --mode default end-of-line accept-autosuggestion
bind \ca --mode default beginning-of-line-or-history-pager
bind \cf --mode default forward-word
bind \cr --mode default backward-word

function beginning-of-line-or-history-pager
  if test -z (commandline)
    commandline -f history-pager
  else
    commandline -f beginning-of-line
  end
end

abbr e $VISUAL
abbr d nnn
abbr l ls -lh

abbr cljcli lein repl
abbr pycli bpython
abbr rbcli pry
abbr jscli node
