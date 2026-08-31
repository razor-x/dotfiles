default: apply

init:
  chezmoi init --apply --source ~/config/dotfiles razor-x

apply:
  chezmoi apply --init --source {{ justfile_directory() }}

update:
  chezmoi update --apply --init

upgrade-biome:
  sd 'schemas/[^/]+/schema\.json' \
    "schemas/$(biome --version | cut --delimiter=' ' --fields=2)/schema.json" \
    biome.json

upgrade: && \
    upgrade-biome \
    upgrade-externals \
    upgrade-neovim \
    upgrade-pi-extensions \
    upgrade-pi-local \
    upgrade-yazi

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
  biome check --write --unsafe .
  fish_indent --write $(git ls-files '*.fish' 'home/.chezmoiscripts/*.fish.tmpl')
  stylua $(git ls-files '*.lua')
  mdformat --exclude '**/skills/**' $(git ls-files '*.md')
  ruff format $(git ls-files '*.py' '*.pyi' '*.ipynb')
  ruff check --fix $(git ls-files '*.py' '*.pyi' '*.ipynb')
  shfmt --write $(git ls-files '*.sh')

check:
  cljfmt check $(git ls-files '*.clj')
  biome check .
  fish_indent --check $(git ls-files '*.fish' 'home/.chezmoiscripts/*.fish.tmpl')
  stylua --check $(git ls-files '*.lua')
  mdformat --exclude '**/skills/**' --check $(git ls-files '*.md')
  ruff format --check $(git ls-files '*.py' '*.pyi' '*.ipynb')
  shfmt --diff $(git ls-files '*.sh')
  fd --type f --extension lua . home/dot_config/exact_nvim/tests \
    --exec nvim --clean --headless -l {}
  npm --prefix home/dot_config/pi/extensions/exact_local run check

upgrade-pi-local: && format
  ./tools/upgrade_pi_local.fish

[working-directory: './home/dot_config/pi/exact_npm']
upgrade-pi-extensions:
  npx --yes --package npm-check-updates@23.1.0 -- ncu --minimal --upgrade
  npm update

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init --force --source {{ justfile_directory() }}

generate:
  chezmoi generate install.sh > bootstrap.sh
  sd 'init --apply' 'init --force --keep-going --apply' bootstrap.sh
  fish --command 'format bootstrap.sh'
