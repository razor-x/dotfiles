#!/bin/sh

set -eu

export NVIM_APPNAME=${1:-nvim}

config_dir=${XDG_CONFIG_HOME:-"$HOME/.config"}/$NVIM_APPNAME
src_url='https://github.com/razor-x/dotfiles/archive/refs/heads/main.tar.gz'

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

download_archive() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$src_url" -o "$1"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -qO "$1" "$src_url"
    return
  fi

  die 'Missing required command: curl or wget'
}

require_cmd mkdir
require_cmd mktemp
require_cmd mv
require_cmd nvim
require_cmd rm
require_cmd tar

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

archive="$tmpdir/dotfiles.tar.gz"
extract_dir="$tmpdir/extract"
source_dir="$extract_dir/dotfiles-main/home/dot_config/exact_nvim"

download_archive "$archive"

printf 'Downloaded %s to %s\n' "$src_url" "$tmpdir"

mkdir -p "$extract_dir"
tar -xzf "$archive" -C "$extract_dir"

[ -d "$source_dir" ] || die "Expected extracted config at $source_dir"

rm -rf "$config_dir"
mkdir -p "$config_dir"

mv "$source_dir/init.lua" "$config_dir/init.lua"
mv "$source_dir/exact_lua" "$config_dir/lua"
mv "$config_dir/lua/exact_plugins" "$config_dir/lua/plugins"
mv "$source_dir/doc" "$config_dir/doc"
mv "$source_dir/.lazy-lock.json" "$config_dir/lazy-lock.json"

nvim --headless '+Lazy! clean' '+Lazy! restore' +qall
nvim --headless "+helptags $config_dir/doc" +qall

printf 'Installed Neovim config to %s\n' "$config_dir"

if [ "$NVIM_APPNAME" != "nvim" ]; then
  printf 'Set NVIM_APPNAME=%s to use this config.\n' "$NVIM_APPNAME"
fi
