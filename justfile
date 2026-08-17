default: watch

init:
  chezmoi init --apply --source ~/config/dotfiles razor-x

apply:
  chezmoi apply --init

update:
  chezmoi update --apply --init

upgrade: && upgrade-externals upgrade-neovim upgrade-pi upgrade-yazi

upgrade-neovim:
  nvim --headless '+Lazy! update' +qall

upgrade-yazi:
  ya pkg upgrade

upgrade-externals:
  ./tools/upgrade_externals.fish

reset:
  chezmoi state delete-bucket --bucket=scriptState;
  chezmoi state delete-bucket --bucket=entryState;
  rm --recursive --force ~/.config/fish
  chezmoi apply --init

format:
  cljfmt fix $(git ls-files '*.clj')
  biome format --write .
  fish_indent --write $(git ls-files '*.fish' 'home/.chezmoiscripts/*.fish.tmpl')
  stylua $(git ls-files '*.lua')
  mdformat $(git ls-files '*.md')
  ruff format $(git ls-files '*.py' '*.pyi' '*.ipynb')
  shfmt --write $(git ls-files '*.sh')

upgrade-pi: && format
  ./tools/upgrade_pi.fish

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init --force

generate:
  chezmoi generate install.sh > bootstrap.sh
  sd 'init --apply' 'init --force --keep-going --apply' bootstrap.sh
  fish --command 'format bootstrap.sh'
