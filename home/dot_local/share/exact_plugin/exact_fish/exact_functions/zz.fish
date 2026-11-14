function zz --description 'Repeat the last z jump'
    if not set -q __dotfiles_last_z_args
        echo 'zz: run z first' >&2
        return 1
    end
    z $__dotfiles_last_z_args
end
