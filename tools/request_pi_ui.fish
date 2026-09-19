#!/usr/bin/env fish

set now (date +%s)
set active
for marker in /tmp/pi-capture-ui.*/active
    test -f $marker; or continue
    set age (math $now - (path mtime $marker))
    test $age -ge 0; and test $age -le 2; or continue
    set --append active (path dirname $marker)
end

if test (count $active) -ne 1
    echo "Expected one active capture helper, found "(count $active)"." >&2
    exit 1
end

set capture_dir $active[1]
set status_file $capture_dir/status
set before
if test -f $status_file
    set before (string collect <$status_file)
end

touch $capture_dir/request
for attempt in (seq 1 60)
    sleep 0.2
    if test -f $status_file
        set current (string collect <$status_file)
        if test "$current" != "$before"; and test -f $capture_dir/capture.png
            echo $capture_dir/capture.png
            exit
        end
    end
end

echo 'Capture request remains pending.' >&2
exit 1
