function load_private_keys
  read -P "Load SSH and GPG keys? [Y/n] " -n 1 response

  set response (string lower (string trim $response))
  if test -z "$response"
    set response "y"
  end

  if test "$response" != "y"
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
