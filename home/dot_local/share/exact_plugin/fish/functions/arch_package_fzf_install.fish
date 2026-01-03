# https://wiki.archlinux.org/title/Fzf#Pacman
function arch_package_fzf_install \
    --wraps 'aura --sync' \
    --description 'Fuzzy-search through all available packages to install'

    set cmd aura --sync

    if test (count $argv) -eq 0
        aura --sync --quiet --list core extra \
            | fzf --multi --preview 'aura --sync --info {1}' \
            | xargs --no-run-if-empty --open-tty $cmd
    else
        $cmd $argv
    end
end
