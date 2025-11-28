#!/usr/bin/env bash

# man hash: {{ include (joinPath .chezmoi.sourceDir "dot_local" "share" "man" "man7" "dotfiles.7") | sha256sum }}

set -u

mandb
