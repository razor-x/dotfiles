function autoload_private_keys --on-variable fish_autoload_private_keys \
    --description 'Prompt user to load SSH and GPG keys into agents'

    if test "$fish_autoload_private_keys" != true
        return
    end

    if ssh-add -l &>/dev/null;
        and gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | grep --quiet '1 P'
        return
    end

    if not confirm_action 'Load SSH and GPG keys?' y
        return
    end

    load_private_keys
end

