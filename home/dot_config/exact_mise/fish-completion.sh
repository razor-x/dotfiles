#!/bin/sh
set -eu

name=$1
dir="$HOME/.local/share/plugin/mise/completions"
mkdir -p "$dir"
tmp=$(mktemp "$dir/.$name.XXXXXX")
trap 'rm -f "$tmp"' EXIT
"$@" >"$tmp"
mv "$tmp" "$dir/$name.fish"
