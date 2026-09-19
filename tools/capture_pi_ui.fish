#!/usr/bin/env fish

# TODO: This only works for X11. Rewrite this when moving to Wayland.

function fail
    echo $argv >&2
    exit 1
end

if test (count $argv) -gt 1
    echo 'Usage: capture_pi_ui.fish [WINDOW_ID]' >&2
    exit 2
end

type --query import; or fail 'ImageMagick import is required.'
type --query xprop; or fail 'xprop is required.'

if test (count $argv) -eq 0
    type --query xdotool; or fail 'xdotool is required to select a window.'
    echo 'Click the dedicated Pi window.' >&2
    set window_id (xdotool selectwindow); or exit
else
    set window_id $argv[1]
    string match --quiet --regex '^(0x[[:xdigit:]]+|[0-9]+)$' -- $window_id
    or fail "Invalid X11 window ID: $window_id"
end

set fingerprint (xprop -id $window_id WM_CLASS _NET_WM_PID 2>/dev/null | string collect)
test $pipestatus[1] -eq 0; or fail "X11 window does not exist: $window_id"
string match --quiet '*WM_CLASS*' -- $fingerprint
and string match --quiet '*_NET_WM_PID*' -- $fingerprint
or fail "Window lacks a stable class/PID identity: $window_id"
string match --quiet --ignore-case '*"kitty"*' -- $fingerprint
or fail "Refusing to capture a non-Kitty window: $window_id"

set temp_root /tmp
set --query TMPDIR; and set temp_root $TMPDIR
set capture_dir (mktemp --directory "$temp_root/pi-capture-ui.XXXXXX"); or exit
chmod 700 $capture_dir
printf '%s\n' $window_id >$capture_dir/window-id
touch $capture_dir/active
printf 'Capture directory: %s\nRequest: touch %s/request\nStop: Ctrl-C\n' $capture_dir $capture_dir

function cleanup --on-event fish_exit --inherit-variable capture_dir
    rm --recursive --force -- $capture_dir
end

set sequence 0
while sleep 0.2
    touch $capture_dir/active
    set request $capture_dir/request
    test -f $request; and not test -L $request; or continue
    rm -- $request

    set current (xprop -id $window_id WM_CLASS _NET_WM_PID 2>/dev/null | string collect)
    if test $pipestatus[1] -ne 0
        fail 'Target window disappeared; stopping.'
    end
    test "$current" = "$fingerprint"; or fail 'Target window identity changed; stopping.'

    set image (mktemp "$capture_dir/.capture.XXXXXX.png"); or exit
    if import -silent -window $window_id $image
        chmod 600 $image
        mv --no-target-directory -- $image $capture_dir/capture.png
        set sequence (math $sequence + 1)
        printf '%s %s\n' $sequence (date +%s) >$capture_dir/.status.new
        mv --no-target-directory -- $capture_dir/.status.new $capture_dir/status
    else
        rm --force -- $image
        echo "Capture failed for window $window_id." >&2
    end
end
