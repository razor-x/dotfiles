#!/usr/bin/env fish

set units \
    "ssh-agent"

if type -q systemctl
    systemctl --user daemon-reload

    for unit in $units
        systemctl --user enable --now $unit
    end
end
