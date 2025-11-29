fish_hybrid_key_bindings

# Fish automatically executes this function.
function fish_user_key_bindings
  bind \
    | grep 'alt-' \
    | string replace -r '^bind\s+(.*?)(alt-\S+)\s.*' 'bind --erase $1$2' \
    | source

    bind --mode default vv edit_command_buffer

    bind ctrl-p --mode insert up-or-search
    bind ctrl-n --mode insert down-or-search
    bind ctrl-e --mode insert end-of-line accept-autosuggestion
    bind ctrl-a --mode insert beginning-of-line-or-history-pager
    bind ctrl-f --mode insert forward-word
    bind ctrl-r --mode insert backward-word
    bind ctrl-b --mode insert backward-delete-char
    bind ctrl-o --mode insert forward-char
    bind ctrl-u --mode insert backward-char
end

function beginning-of-line-or-history-pager
  if test -z (commandline)
    commandline -f history-pager
  else
    commandline -f beginning-of-line
  end
end
