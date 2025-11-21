fish_hybrid_key_bindings
bind -M default vv edit_command_buffer

bind \ce end-of-line accept-autosuggestion
bind \ca beginning-of-line-or-history-pager
bind \cf forward-bigword
bind \cr backward-bigword

function beginning-of-line-or-history-pager
  if test -z (commandline)
    commandline -f history-pager
  else
    commandline -f beginning-of-line
  end
end

abbr vv $VISUAL
