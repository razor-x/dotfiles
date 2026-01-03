default: watch

apply:
  chezmoi apply --init

update:
  chezmoi update --apply --init

reset:
  chezmoi state delete-bucket --bucket=scriptState;
  chezmoi state delete-bucket --bucket=entryState;
  rm --recursive --force ~/.config/fish
  chezmoi apply --init

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init
