#!/usr/bin/env fish

set units \
    atuin \
    ssh-agent

if type --query systemctl
    systemctl --user daemon-reload

    for unit in $units
        systemctl --user enable --now $unit
    end
else
    echo 'Cannot setup systemd user units: systemctl not found.'
    return 1
end
