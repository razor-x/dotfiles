# Clear Fish greeting.
set fish_greeting

if status is-interactive
  if not set -q SSH_CONNECTION
    load_private_keys
  end

  if set -q SSH_CONNECTION; and not set -q TMUX
    set fish_tmux_autostart true
  end
end
