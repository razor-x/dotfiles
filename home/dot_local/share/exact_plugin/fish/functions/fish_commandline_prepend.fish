# UPSTREAM: The fish_commandline_prepend function will not toggle if any meta character is present.
# https://github.com/fish-shell/fish-shell/issues/8763
function fish_commandline_prepend --description "Prepend the given string to the command-line, or remove the prefix if already there"
    if not commandline | string length -q
        commandline -r $history[1]
    end

    set -l process (commandline | string collect)

    set -l to_prepend "$argv[1] "
    if string match -qr '^ ' "$process"
        set to_prepend " $argv[1]"
    end

    set -l length_diff (string length -- "$to_prepend")
    set -l cursor_location (commandline -C)

    set -l escaped (string escape --style=regex -- $to_prepend)
    if set -l process (string replace -r -- "^$escaped" "" $process)
        commandline --replace -- $process
        set length_diff "-$length_diff"
    else
        commandline -C 0
        commandline -i -- "$to_prepend"
    end

    commandline -C (math "max 0,($cursor_location + $length_diff)")
end
