function load_private_keys \
    --description 'Load SSH keys into the ssh-agent and GPG keys into the GPG agent'

    if not ssh-add -l &>/dev/null
        ssh-add
    end

    if not gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | grep -q '1 P'
        echo '' | gpg --clearsign --armor &>/dev/null
    end
end
