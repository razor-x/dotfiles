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
    --extension ts \
    . \
    | xargs \
        --null \
        --no-run-if-empty \
        --max-args 1 \
        fish --command 'format $argv[1]' --
  fd \
    --print0 \
    --hidden \
    --type file \
    --glob '*.fish.tmpl' \
    home/.chezmoiscripts/ \
    | xargs \
        --null \
        --no-run-if-empty \
        --max-args 1 \
        fish --command 'format --extension fish $argv[1]' --

pi-local-extension-env-update:
  #!/usr/bin/env bash
  set -euo pipefail

  extension_dir="home/dot_config/pi/extensions/exact_local"
  mkdir -p "$extension_dir"

  pi_info="$(npm view \
    @earendil-works/pi-coding-agent@latest \
    version \
    devDependencies \
    --json)"

  pi_version="$(jq --raw-output \
    'if type == "array" then .[0].version else .version end' \
    <<< "$pi_info")"

  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "https://raw.githubusercontent.com/earendil-works/pi/v$pi_version/tsconfig.base.json" \
    --output "$extension_dir/tsconfig.base.json"
  typescript_version="$(jq --raw-output \
    'if type == "array" then .[0].devDependencies.typescript else .devDependencies.typescript end' \
    <<< "$pi_info")"
  node_types_version="$(jq --raw-output \
    'if type == "array" then .[0].devDependencies["@types/node"] else .devDependencies["@types/node"] end' \
    <<< "$pi_info")"
  ai_version="$(npm view \
    "@earendil-works/pi-ai@$pi_version" \
    version \
    --json \
    | jq --raw-output 'if type == "array" then .[0] else . end')"
  tui_version="$(npm view \
    "@earendil-works/pi-tui@$pi_version" \
    version \
    --json \
    | jq --raw-output 'if type == "array" then .[0] else . end')"

  jq --null-input \
    --arg pi_version "$pi_version" \
    --arg ai_version "$ai_version" \
    --arg tui_version "$tui_version" \
    --arg node_types_version "$node_types_version" \
    --arg typescript_version "$typescript_version" \
    '{
      "name": "pi-local-extension",
      "private": true,
      "type": "module",
      "scripts": {
        "typecheck": "tsc -p tsconfig.json"
      },
      "devDependencies": {
        "@earendil-works/pi-ai": $ai_version,
        "@earendil-works/pi-coding-agent": $pi_version,
        "@earendil-works/pi-tui": $tui_version,
        "@types/node": $node_types_version,
        "typescript": $typescript_version
      }
    }' \
    > "$extension_dir/package.json"

  jq --null-input \
    '{
      "extends": "./tsconfig.base.json",
      "compilerOptions": {
        "noEmit": true
      },
      "include": ["**/*.ts"],
      "exclude": ["node_modules"]
    }' \
    > "$extension_dir/tsconfig.json"

  npm install --prefix "$extension_dir"
  npm run --prefix "$extension_dir" typecheck

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init --force

generate:
  chezmoi generate install.sh > bootstrap.sh
  sd 'init --apply' 'init --force --keep-going --apply' bootstrap.sh
  fish --command 'format bootstrap.sh'
