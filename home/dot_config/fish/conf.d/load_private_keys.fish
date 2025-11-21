function load_private_keys
  confirm_action "Load SSH and GPG keys?"

  if not confirm_action
    return
  end

  # Load all SSH keys into the ssh-agent.
  if not ssh-add -l &>/dev/null
    ssh-add
  end

  # Load GPG key into the ssh-agent.
  if not gpg-connect-agent 'keyinfo --list' /bye 2>/dev/null | grep -q "1 P"
    echo "" | gpg --clearsign --armor &>/dev/null
  end
end
