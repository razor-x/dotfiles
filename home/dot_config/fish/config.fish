# Clear Fish greeting.
set fish_greeting

# Detect SSH session.
set -l is_ssh_session false
if set -q SSH_CLIENT; or set -q SSH_TTY
  set is_ssh_session true
end

if status is-interactive
  if not $is_ssh_session
    load_private_keys
  end

  if $is_ssh_session
    set fish_tmux_autostart true
  end
end
