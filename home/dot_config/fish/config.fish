# Clear Fish greeting.
set fish_greeting

if status is-interactive
  # Use simple fish prompt in Linux  virtual console.
  if test "$TERM" = "linux"
    fish_config prompt choose default
  end

  if not set -q SSH_CONNECTION; and test "$TERM" != "linux"
    load_private_keys
  end

  if set -q SSH_CONNECTION; and not set -q TMUX
    set fish_tmux_autostart true
  end
end
