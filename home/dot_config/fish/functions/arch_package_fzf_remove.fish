# https://wiki.archlinux.org/title/Fzf#Pacman
function arch_package_fzf_remove \
    --wraps 'aura --remove --nosave --recursive' \
    --description 'Fuzzy-search through all available packages to install'

    set cmd aura --remove --nosave --recursive

    if test (count $argv) -eq 0
        aura --sync --quiet --list core extra \
            | fzf --multi --preview 'aura --query --info {1}' \
            | xargs --no-run-if-empty --open-tty $cmd
    else
        $cmd $argv
    end
end
