# https://yazi-rs.github.io/docs/quick-start#shell-wrapper
function yazi_change_cwd \
    --wraps yazi \
    --description 'Change the current working directory when exiting Yazi'

    set --function tmp (mktemp --tmpdir 'yazi-cwd.XXXXXX')
    yazi $argv --cwd-file="$tmp"
    if read --null cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm --force -- "$tmp"
end
