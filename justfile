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
  #!/usr/bin/env bash
  set -o errexit
  set -o nounset
  set -o pipefail

  externals=home/.chezmoiexternal.yaml
  download=$(mktemp)
  entries=$(mktemp)
  updater=$(mktemp)
  trap 'rm --force "$download" "$entries" "$updater"' EXIT

  cat > "$updater" <<'PYTHON'
  import os
  import sys
  from pathlib import Path

  path = Path(sys.argv[1])
  text = path.read_text()
  target = os.environ["TARGET"]
  old_url = os.environ["OLD_URL"]
  new_url = os.environ["NEW_URL"]
  old_sha256 = os.environ["OLD_SHA256"]
  new_sha256 = os.environ["NEW_SHA256"]

  marker = f"{target}:"
  lines = text.splitlines(keepends=True)

  try:
      start = next(index for index, line in enumerate(lines) if line.rstrip("\r\n") == marker)
  except StopIteration as error:
      raise SystemExit(f"external not found: {target}") from error

  end = next(
      (
          index
          for index in range(start + 1, len(lines))
          if lines[index] and not lines[index][0].isspace() and not lines[index].startswith("#")
      ),
      len(lines),
  )

  block = "".join(lines[start:end])
  if block.count(old_url) != 1:
      raise SystemExit(f"URL not found exactly once for external: {target}")
  if block.count(old_sha256) != 1:
      raise SystemExit(f"checksum not found exactly once for external: {target}")

  lines[start:end] = [
      block.replace(old_url, new_url, 1).replace(old_sha256, new_sha256, 1)
  ]
  path.write_text("".join(lines))
  PYTHON

  latest_release() {
    gh release view \
      --repo "$1" \
      --json tagName \
      --jq .tagName 2>/dev/null
  }

  head_commit() {
    local repo=$1 branch

    branch=$(gh api "repos/$repo" --jq .default_branch)
    gh api "repos/$repo/commits/$branch" --jq .sha
  }

  resolve_url() {
    local url=$1 owner repo asset path ref

    # GitHub source archives pinned to release tags.
    if [[ $url =~ ^https://github\.com/([^/]+)/([^/]+)/archive/refs/tags/[^/]+\.tar\.gz$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      ref=$(latest_release "$owner/$repo")

      printf 'https://github.com/%s/%s/archive/refs/tags/%s.tar.gz\n' \
        "$owner" "$repo" "$ref"
      return
    fi

    # GitHub source archives pinned to commits.
    if [[ $url =~ ^https://github\.com/([^/]+)/([^/]+)/archive/[[:xdigit:]]{40}\.tar\.gz$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      ref=$(head_commit "$owner/$repo")

      printf 'https://github.com/%s/%s/archive/%s.tar.gz\n' \
        "$owner" "$repo" "$ref"
      return
    fi

    # Raw GitHub files pinned to release tags.
    if [[ $url =~ ^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/tags/[^/]+/(.+)$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      path=${BASH_REMATCH[3]}
      ref=$(latest_release "$owner/$repo")

      printf 'https://raw.githubusercontent.com/%s/%s/refs/tags/%s/%s\n' \
        "$owner" "$repo" "$ref" "$path"
      return
    fi

    # Raw GitHub files pinned to branches.
    if [[ $url =~ ^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/heads/[^/]+/(.+)$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      path=${BASH_REMATCH[3]}
      ref=$(head_commit "$owner/$repo")

      printf 'https://raw.githubusercontent.com/%s/%s/%s/%s\n' \
        "$owner" "$repo" "$ref" "$path"
      return
    fi

    # Raw GitHub files pinned to commits.
    if [[ $url =~ ^https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/[[:xdigit:]]{40}/(.+)$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      path=${BASH_REMATCH[3]}
      ref=$(head_commit "$owner/$repo")

      printf 'https://raw.githubusercontent.com/%s/%s/%s/%s\n' \
        "$owner" "$repo" "$ref" "$path"
      return
    fi

    # GitHub release assets: preserve the asset name and update the release.
    if [[ $url =~ ^https://github\.com/([^/]+)/([^/]+)/releases/download/[^/]+/(.+)$ ]]; then
      owner=${BASH_REMATCH[1]}
      repo=${BASH_REMATCH[2]}
      asset=${BASH_REMATCH[3]}
      ref=$(latest_release "$owner/$repo")

      printf 'https://github.com/%s/%s/releases/download/%s/%s\n' \
        "$owner" "$repo" "$ref" "$asset"
      return
    fi

    # Non-GitHub/mutable URLs retain their current location.
    printf '%s\n' "$url"
  }

  yq --unwrapScalar '
    to_entries[]
    | select(.value.checksum.sha256 != null)
    | [.key, .value.url, .value.checksum.sha256]
    | @tsv
  ' "$externals" > "$entries"

  while IFS=$'\t' read -r target old_url old_sha256; do
    new_url=$(resolve_url "$old_url")

    curl \
      --fail \
      --location \
      --silent \
      --show-error \
      --output "$download" \
      "$new_url"

    checksum=$(sha256sum "$download")
    checksum=${checksum%% *}

    TARGET=$target \
      OLD_URL=$old_url \
      NEW_URL=$new_url \
      OLD_SHA256=$old_sha256 \
      NEW_SHA256=$checksum \
      python "$updater" "$externals"

    if [[ $old_url == "$new_url" ]]; then
      printf 'refreshed %s\n' "$target"
    else
      printf 'updated %s\n  %s\n  %s\n' \
        "$target" "$old_url" "$new_url"
    fi
  done < "$entries"

  git diff -- "$externals"

reset:
  chezmoi state delete-bucket --bucket=scriptState;
  chezmoi state delete-bucket --bucket=entryState;
  rm --recursive --force ~/.config/fish
  chezmoi apply --init

format:
  cljfmt fix $(git ls-files '*.clj')
  biome format --write .
  fish_indent --write $(git ls-files '*.fish' 'home/.chezmoiscripts/*.fish.tmpl')
  stylua .
  mdformat $(git ls-files '*.md')
  ruff format .
  shfmt --write $(git ls-files '*.sh')

[working-directory: 'home/dot_config/pi/extensions/exact_local']
upgrade-pi: && format
  #!/usr/bin/env bash
  set -euo pipefail

  pi_info="$(npm view --json \
    @earendil-works/pi-coding-agent@latest \
    dependencies devDependencies engines version)"

  pi_version="$(jq --raw-output .[0].version <<< "$pi_info")"

  curl \
    --fail \
    --silent \
    --show-error \
    --location \
    "https://raw.githubusercontent.com/earendil-works/pi/v${pi_version}/tsconfig.base.json" \
    --output tsconfig.base.json

  typescript_version="$(jq --raw-output '.[0].devDependencies.typescript' <<< "$pi_info")"
  node_types_version="$(jq --raw-output '.[0].devDependencies["@types/node"]' <<< "$pi_info")"
  typebox_version="$(jq --raw-output '.[0].dependencies["typebox"]' <<< "$pi_info")"
  ai_version="$(jq --raw-output '.[0].dependencies["@earendil-works/pi-ai"]' <<< "$pi_info")"
  tui_version="$(jq --raw-output '.[0].dependencies["@earendil-works/pi-tui"]' <<< "$pi_info")"
  engines="$(jq --compact-output '.[0].engines' <<< "$pi_info")"

  package_json="$(mktemp package.json.XXXXXX)"
  trap 'rm --force "$package_json"' EXIT

  jq \
    --arg pi_version "$pi_version" \
    --arg ai_version "$ai_version" \
    --arg tui_version "$tui_version" \
    --arg typebox_version "$typebox_version" \
    --arg node_types_version "$node_types_version" \
    --arg typescript_version "$typescript_version" \
    --argjson engines "$engines" \
    '
      .name = "pi-local-extension"
      | .engines = $engines
      | .devDependencies["@earendil-works/pi-ai"] = $ai_version
      | .devDependencies["@earendil-works/pi-coding-agent"] = $pi_version
      | .devDependencies["@earendil-works/pi-tui"] = $tui_version
      | .devDependencies["@types/node"] = $node_types_version
      | .devDependencies["typebox"] = $typebox_version
      | .devDependencies["typescript"] = $typescript_version
    ' \
    package.json \
    > "$package_json"

  mv "$package_json" package.json
  trap - EXIT

  npm install
  npm run typecheck
  npm --prefix ../../exact_npm update

watch:
  watchexec --watch $(chezmoi source-path) -- chezmoi apply --init --force

generate:
  chezmoi generate install.sh > bootstrap.sh
  sd 'init --apply' 'init --force --keep-going --apply' bootstrap.sh
  fish --command 'format bootstrap.sh'
