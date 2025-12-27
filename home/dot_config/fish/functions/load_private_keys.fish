function load_private_keys \
    --description 'Load SSH keys into the ssh-agent and GPG keys into the GPG agent'

    if not ssh-add -l &>/dev/null
        ssh-add
    else
        echo 'SSH keys already loaded.'
    end

    if not gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null \
        | string match --regex --quiet '1 P'
        echo '' | gpg --clearsign --armor &>/dev/null
    else
        echo 'GPG keys already loaded.'
    end
end
