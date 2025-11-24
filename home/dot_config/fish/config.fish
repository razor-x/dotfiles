# Clear Fish greeting.
set fish_greeting

if status is-interactive
  # Use simple fish prompt in Linux virtual console.
  if test "$TERM" = "linux"
    fish_config prompt choose default
  end

  # Limit when prompted to load keys.
  if not set -q SSH_CONNECTION; and test "$TERM" != "linux"
    set fish_autoload_private_keys true
  end

  # Autostart tmux when connecting though SSH and client is not using tmux.
  if set -q SSH_CONNECTION; and not set -q TMUX
    set fish_tmux_autostart true
  end
end
