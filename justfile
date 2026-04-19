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
    --hidden \
    --exclude .lazy-lock.json \
    --type file \
    --extension clj \
    --extension fish \
    --extension json \
    --extension lua \
    --extension md \
    --extension py \
    --extension sh \
    . \
    | xargs \
        --null \
        --no-run-if-empty \
        --max-args 1 \
        fish --command 'format $argv[1]' --

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init --force

generate:
  chezmoi generate install.sh > bootstrap.sh
  sd 'init --apply' 'init --force --keep-going --apply' bootstrap.sh
  fish --command 'format bootstrap.sh'
