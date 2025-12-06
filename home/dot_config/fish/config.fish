# Clear Fish greeting.
set --global fish_greeting

if status is-interactive
    # Configure pinentry to use the correct TTY.
    # This must be done separately for each shell.
    # https://wiki.archlinux.org/title/GnuPG#Configure_pinentry_to_use_the_correct_TTY
    set --global GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null

    # Use simple fish prompt in Linux virtual console.
    if test "$TERM" = linux
        fish_config prompt choose default
    end

    # Limit when prompted to load keys.
    if not set --query SSH_CONNECTION; and test "$TERM" != linux
        set fish_autoload_private_keys true
    end

    # Autostart Zellij when connecting though SSH and not multiplexing.
    if set --query SSH_CONNECTION;
        and not set --query TMUX;
        and not set --query ZELLIJ;
        and test "$TERM" != xterm-kitty

        zellij attach --create ssh
        zellij delete-session ssh
        kill $fish_pid
    end
end
