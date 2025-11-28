# Clear Fish greeting.
set fish_greeting

if status is-interactive
  # Use batpipe as the less preprocessor.
  eval (batpipe)

  # User batman as the MANPAGER.
  batman --export-env | source

  # Use zoxide.
  zoxide init fish | source

  # Erase bindings after all plugins are loaded.
  fish_erase_alt_key_bindings

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
    zellij delete-session ssh
    kill $fish_pid
  end
end
