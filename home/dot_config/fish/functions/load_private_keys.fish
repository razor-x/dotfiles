function load_private_keys
    # Load all SSH keys into the ssh-agent.
    if not ssh-add -l &>/dev/null
        ssh-add
    end

    # Load GPG key into the ssh-agent.
    if not gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | grep -q '1 P'
        echo '' | gpg --clearsign --armor &>/dev/null
    end
end

function autoload_private_keys --on-variable fish_autoload_private_keys
    if test "$fish_autoload_private_keys" != true
        return
    end

    if not confirm_action 'Load SSH and GPG keys?' y
        return
    end

    load_private_keys
end
