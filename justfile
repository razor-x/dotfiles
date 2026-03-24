default: watch

init:
  chezmoi init --apply --source ~/config/dotfiles razor-x

apply:
  chezmoi apply --init

update:
  chezmoi update --apply --init

reset:
  chezmoi state delete-bucket --bucket=scriptState;
  chezmoi state delete-bucket --bucket=entryState;
  rm --recursive --force ~/.config/fish
  chezmoi apply --init

format:
  fd --extension fish --type file --print0 . home | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --
  fd --extension lua --type file --print0 . home | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --
  fd --extension json --type file --print0 . home | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --
  fd --extension md --type file --print0 . | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --
  fd --extension py --type file --print0 . home | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --
  fd --extension clj --type file --print0 . home | xargs --null --no-run-if-empty --max-args 1 fish --command 'format $argv[1]' --

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init
