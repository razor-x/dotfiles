# Global Pi instructions

Use the local CLI tools when they are a good fit. Prefer:

## Files and text

- `fd` instead of `find` for locating files.
- `rg` instead of `grep` for searching text.
- `rga` (`ripgrep-all`) when searching PDFs, archives, ebooks, or office documents.
- `sd` instead of `sed` for straightforward find-and-replace operations.
- `bat` instead of `cat` for readable file previews.
- `eza` instead of `ls`; use `tree` when a depth-oriented directory view is useful.

## Structured data and documentation

- `yq` for YAML or JSON transformations.
- `fq` for inspecting binary data and structured formats.
- `glow` for rendering Markdown in the terminal.
- `tealdeer` (`tldr`) or `navi` for concise command help when needed.
- `pandoc` for document-format conversion.

## Repository and Git

- Use `just` recipes when a suitable repository task exists.
- Use `git` for scripted or precise repository operations.
- Use `gh` for GitHub issues, pull requests, and repository operations.
  - Use GitHub over HTTPS but never change a remote url in a repo from ssh to https.
  - For task-relevant context from another GitHub repository, use the `repo-scout` skill to clone it temporarily with `gh`.
  - For authenticated Git commands, leave the global config and remotes unchanged and supply the `gh` credential helper per command:
    `git -c credential.https://github.com.helper= -c credential.https://github.com.helper='!gh auth git-credential' …`.
- Treat global Git and GitHub authentication config as read-only; never run `gh auth setup-git` or modify it.
- Use `worktrunk` for Git worktree management when working with parallel branches or agents.

## Archives, files, and network

- Use `ouch` for common archive compression and extraction.
- Use `7z`, `unzip`, or `zip` when the format requires it.
- Use `xh` for HTTP requests; use `curl` or `wget` when scripting or when their specific options are needed.
- Use `rclone` for cloud-storage file operations and `rsync` for efficient local/remote synchronization.
- Use `sponge` from `moreutils` when a pipeline needs to safely replace its input file.

## System inspection

- Use `dust` or `dua` instead of `du` for disk-usage exploration.
- Use `procs` instead of `ps` for readable process inspection.
- Use `lsof` to determine which processes have files or sockets open.

## Pi self-modification

Docs are installed at `/usr/share/doc/pi` on Arch Linux.

When modifying Pi's global instructions or local extension, edit
`$HOME/config/dotfiles/home/dot_config/pi/AGENTS.md` or
`$HOME/config/dotfiles/home/dot_config/pi/extensions/exact_local`.

Their installed runtime copies are under `$XDG_CONFIG_HOME/pi`; do not edit
them directly. After changing either source, run `pi-sync-dotfiles`, then reload Pi.
