#!/bin/sh
set -eu

name=$1
dir="${MISE_FISH_COMPLETIONS_DIR:-$HOME/.local/share/plugin/mise/completions}"
mkdir --parents -- "$dir"
tmp=$(mktemp -- "$dir/.$name.XXXXXX")
trap 'rm --force -- "$tmp"' EXIT
"$@" >"$tmp"
mv "$tmp" "$dir/$name.fish"
