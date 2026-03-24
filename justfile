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
  fd \
    --print0 \
    --type file \
    --extension clj \
    --extension fish \
    --extension json \
    --extension lua \
    --extension md \
    --extension py \
    . \
    | xargs \
        --null \
        --no-run-if-empty \
        --max-args 1 \
        fish --command 'format $argv[1]' --

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init
