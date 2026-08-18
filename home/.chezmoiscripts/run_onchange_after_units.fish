#!/usr/bin/env fish

# hash: {{ template "user_env_hash" . }}

# Do not delete items from this list: move them to units_to_disable instead.
set --local units_to_enable \
    atuin \
    ssh-agent

set --local units_to_disable

if type --query systemctl
    systemctl --user daemon-reload
    or exit

    for unit in $units_to_enable
        systemctl --user enable $unit
        or exit
        systemctl --user restart $unit
        or exit
    end

    for unit in $units_to_disable
        systemctl --user stop $unit
        or exit
        systemctl --user disable $unit
        or exit
    end
else
    echo 'Cannot setup systemd user units: systemctl not found.'
    return 1
end
