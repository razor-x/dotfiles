# Clear Fish greeting.
set fish_greeting

if status is-interactive
  # Use default fish prompt in Linux  virtual console.
  if test "$TERM" = "linux"
    functions --erase fish_prompt
    functions --erase fish_right_prompt
    functions --erase fish_mode_prompt
  end

  if not set -q SSH_CONNECTION
    load_private_keys
  end

  if set -q SSH_CONNECTION; and not set -q TMUX
    set fish_tmux_autostart true
  end
end
