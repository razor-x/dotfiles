# https://wiki.archlinux.org/title/Fzf#Pacman
function arch_package_fzf_remove \
    --description 'Fuzzy-search through all available packages to install'

    aura --sync --quiet --list core extra \
        | fzf --multi --preview 'aura --query --info {1}' \
        | xargs --no-run-if-empty --open-tty aura --remove --notsaved --search
end
