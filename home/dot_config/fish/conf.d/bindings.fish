bind \ce end-of-line accept-autosuggestion
bind \ca beginning-of-line-or-history-pager
bind \cf forward-bigword
bind \cr backward-bigword

fish_vi_key_bindings
bind -M default vv edit_command_buffer

function beginning-of-line-or-history-pager
  if test -z (commandline)
    commandline -f history-pager
  else
    commandline -f beginning-of-line
  end
end
