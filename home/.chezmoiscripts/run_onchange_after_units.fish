#!/usr/bin/env fish

# hash: {{ template "user_env_hash" . }}

set --local units \
    atuin \
    ssh-agent

if type --query systemctl
    systemctl --user daemon-reload

    for unit in $units
        systemctl --user enable $unit
        systemctl --user restart $unit
    end
else
    echo 'Cannot setup systemd user units: systemctl not found.'
    return 1
end
