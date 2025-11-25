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

  # Autostart Zellij when connecting though SSH and not multiplexing.
  if set -q SSH_CONNECTION; and not set -q TMUX; and not set -q ZELLIJ;
    zellij attach --create ssh
    kill $fish_pid
  end
end
