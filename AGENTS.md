# AGENTS.md

This document provides essential information for AI agents working in this dotfiles repository.

## Overview

This is a **chezmoi-managed dotfiles repository** for Arch Linux user land configuration. The repository uses chezmoi's templating system extensively to manage configuration files across multiple tools and applications.

**Key characteristics:**
- All source files live under `home/` directory (defined in `.chezmoiroot`)
- Actual dotfiles are deployed to `~/` when applied
- Heavy use of templating (`.tmpl` files) for dynamic configuration
- Theme system with Catppuccin support across multiple applications
- Integration with Fish shell, Neovim, Kitty, Zellij, and other CLI tools
- Always use long CLI flags instead of short ones

## Essential Commands

Do NOT run chezmoi commands or just commands: the user is responsible for running those.

### Navigation

Change to dotfiles source directory:
```sh
dotfiles  # This is an alias/function defined in the user's shell
# OR directly:
cd ~/config/dotfiles
```

### Git Operations

This is a git repository. Use standard git commands:
```sh
git status
git add <files>
git commit -m "message"
git push
```

Check recent commit patterns for style reference - commits are typically concise and imperative (e.g., "Add lspconfig", "Move bat environment vars", "Fix typo").

## Repository Structure

### Directory Layout

```
/home/razorx/config/dotfiles/
├── .chezmoiroot                    # Contains "home" - sets source root
├── home/                           # Source directory (maps to ~/)
│   ├── .chezmoi.yaml.tmpl          # Chezmoi configuration with theme data
│   ├── .chezmoiexternal.yaml       # External resources (Catppuccin themes, etc.)
│   ├── .chezmoiignore              # Files to not apply
│   ├── .chezmoiremove              # Files to remove from target
│   ├── .chezmoiscripts/            # Run scripts on apply
│   │   ├── run_onchange_*.fish*    # Scripts that run when content changes
│   │   └── .man_from_readme.fish   # Utility script
│   ├── .chezmoitemplates/          # Reusable templates
│   │   ├── bash_env                # Bash environment loader
│   │   ├── catppuccin              # Catppuccin theme selector
│   │   ├── theme                   # Generic theme selector
│   │   └── user_env_hash           # Hash of environment.d configs
│   ├── dot_config/                 # Maps to ~/.config/
│   │   ├── exact_nvim/             # Neovim config (exact = managed exclusively)
│   │   ├── fish/                   # Fish shell config
│   │   ├── exact_kitty/            # Kitty terminal config
│   │   ├── exact_zellij/           # Zellij config
│   │   ├── exact_yazi/             # Yazi file manager config
│   │   ├── exact_git/              # Git config
│   │   ├── exact_environment.d/    # Environment variables
│   │   └── ...                     # Other tool configs
│   ├── dot_local/
│   │   ├── exact_bin/              # Local executables
│   │   └── share/                  # Local data files
│   ├── dot_ssh/                    # SSH configuration
│   ├── dot_bashrc.tmpl             # Bash configuration (auto-starts Fish)
│   └── dot_bash_profile            # Bash login profile
├── justfile                        # Just command runner recipes
├── .editorconfig                   # Editor configuration
├── README.md                       # User documentation
└── TODO                            # Development notes
```

### Chezmoi Naming Conventions

Chezmoi uses special prefixes in filenames:

- `dot_` → `.` (e.g., `dot_bashrc` → `.bashrc`)
- `exact_` → Directory managed exclusively by chezmoi (removes untracked files)
- `private_` → Restricts permissions (e.g., `private_gnupg`)
- `symlink_` → Creates a symlink
- `.tmpl` suffix → Template file (processed with Go templates)
- `run_onchange_` → Script runs when its content changes
- `run_onchange_after_` → Script runs after files are applied

## Code Organization

### Configuration Management

**Theme System:**
- Central theme configuration in `home/.chezmoi.yaml.tmpl`
- Template `{{ template "theme" (merge (dict "app" "kitty") .) }}` selects themes
- Template `{{ template "catppuccin" . }}` handles Catppuccin-specific logic
- Supports per-application theme overrides
- Default theme is Catppuccin with configurable flavors (macchiato/latte) and accents

**External Resources:**
- Defined in `home/.chezmoiexternal.yaml`
- Includes Catppuccin themes, vim plugins for Kitty/Zellij, external tools
- Uses checksums for verification

**Environment Variables:**
- Managed in `home/dot_config/exact_environment.d/*.conf.tmpl`
- Loaded dynamically via `bash_env` template
- Hashed to detect staleness (`user_env_hash` template)

### Application-Specific Configs

**Fish Shell (`home/dot_config/fish/`):**
- Main config: `config.fish`
- Plugins managed via Fisher: `fish_plugins`
- Plugin sources: `~/.local/share/plugin/fish` (last line in fish_plugins)
- Scripts update fish theme, plugins, and Tide prompt via `run_onchange_after_fish.fish.tmpl`
- Automatically starts Zellij when connecting via SSH

**Neovim (`home/dot_config/exact_nvim/`):**
- Entry point: `init.lua`
- Configuration module: `lua/config/`
  - `init.lua` - Main setup orchestration
  - `plugins.lua` - Plugin specifications (uses lazy.nvim)
  - `lazy.lua` - Lazy.nvim bootstrap
  - `dotfiles.lua.tmpl` - Dotfiles source directory reference
- Lockfile: `.lazy-lock.json` (in source directory, not target)
- Uses mini.nvim, smart-splits, cutlass, kitty-scrollback
- Legacy vim config: `legacy.vim`

**Kitty (`home/dot_config/exact_kitty/`):**
- Main config: `kitty.conf.tmpl`
- Includes: `preferences.conf`, `mouse.conf`, `keymap.conf`, `oneshot.conf`
- Smart-splits and kitty-scrollback integration via external files
- Theme applied via `current-theme.conf` (generated, ignored in `.chezmoiignore`)

**Git (`home/dot_config/exact_git/`):**
- Main config: `config` (uses tabs for indentation - see `.editorconfig`)
- User info: `user.tmpl`

**SSH (`home/dot_ssh/`):**
- `authorized_keys.tmpl` - Authorized keys from GitHub
- `config` - SSH client configuration

### Scripts and Automation

**Chezmoi Scripts (`home/.chezmoiscripts/`):**

All scripts use hash-based change detection. They only run when content changes.

- `run_onchange_after_fish.fish.tmpl` - Updates Fish theme, plugins, Tide configuration
- `run_onchange_after_kitty.fish.tmpl` - Kitty setup tasks
- `run_onchange_after_man.fish.tmpl` - Manual page setup
- `run_onchange_after_units.fish` - User unit management
- `run_onchange_after_yazi_package.fish.tmpl` - Yazi package management
- `run_onchange_broot.fish.tmpl` - Broot configuration
- `run_onchange_gh.fish` - GitHub CLI setup (sets protocol to SSH, aliases)
- `run_onchange_nushell_atuin.nu` - Nushell/Atuin setup
- `.man_from_readme.fish` - Utility for generating man pages

Scripts check for command availability before execution and return with helpful error messages if tools are missing.

## Code Style and Conventions

### Indentation (from `.editorconfig`)

- **Default:** 2 spaces
- **Fish (`.fish`, `.fish.tmpl`):** 4 spaces
- **KDL (`.kdl`, `.kdl.tmpl`):** 4 spaces
- **RON (`.ron`, `.ron.tmpl`):** 4 spaces
- **Git config (`home/dot_config/exact_git/*`):** Tabs (size 4)

### File Encoding

- UTF-8
- LF line endings
- Insert final newline
- Trim trailing whitespace

### Template Syntax

**Go Template Delimiters:**
```
{{ .variable }}
{{ template "name" . }}
{{ range .list }}...{{ end }}
{{ if condition }}...{{ end }}
```

**Common Template Variables:**
- `.chezmoi.homeDir` - User's home directory
- `.chezmoi.sourceDir` - Dotfiles source directory
- `.chezmoi.hostname` - Current hostname
- `.theme` - Selected theme name
- `.themes` - Theme configuration map
- `.catppuccin` - Catppuccin theme settings
- `.fonts.kitty` - Kitty font family

**Template Functions:**
- `{{ include "path" }}` - Include file contents
- `{{ sha256sum "string" }}` - SHA256 hash
- `{{ output "command" "args" }}` - Run command and capture output
- `{{ joinPath "a" "b" }}` - Join path components
- `{{ env "VAR" }}` - Get environment variable

### Git Commit Style

Based on recent commits:
- Imperative mood: "Add X", "Move Y", "Fix Z", "Remove A", "Update B"
- Concise single-line messages
- No periods at the end
- Specific and descriptive

Examples:
```
Add lspconfig
Move bat environment vars
Fix typo
Handle caddy_file_server args
```

## Important Gotchas

### File Removal

**CRITICAL:** When removing source files that are **not** under an `exact_` path, you **MUST** add the removed files to `home/.chezmoiremove`. Otherwise, chezmoi will not remove them from the target directory.

Files under `exact_` directories are automatically removed from the target when removed from the source.

### Template vs Non-Template Files

- Files with `.tmpl` suffix are processed as Go templates
- Template syntax in non-`.tmpl` files will be treated as literal text
- When adding templates, ensure proper escaping of `{{` and `}}` if they should be literal

### Script Execution

- `run_onchange_*` scripts only execute when their content changes
- Hash comments at the top of scripts (e.g., `# hash: {{ sha256sum $hash }}`) track dependencies
- Scripts that depend on external state use hashes to detect changes
- Scripts run with their interpreter (shebang line), not directly

### State Management

- Chezmoi maintains state in buckets: `scriptState`, `entryState`
- `just reset` clears this state, forcing scripts to re-run
- Fish config is deleted on reset to ensure clean reapplication

### Ignored Files

Check `home/.chezmoiignore` for files that chezmoi should not manage:
- Generated kitty themes
- Nushell history
- Yazi _package.toml (symlinked)
- Yazi plugins and flavors directories
- Neovim config (only on certain hostnames)

### External Resources

- External files defined in `.chezmoiexternal.yaml` are fetched on apply
- Checksums ensure integrity
- If upstream URLs change, update both URL and checksum

### Hostname-Specific Configuration

Some configs are hostname-specific (e.g., nvim only on "minto" and "anny"):
```go
{{ if not (has .chezmoi.hostname (list "minto" "anny")) -}}
.config/nvim/**
{{ end -}}
```

Check `.chezmoiignore` for these patterns.

### Theme Configuration

- Themes are centrally configured in `.chezmoi.yaml.tmpl`
- Each app can override the global theme
- Catppuccin has special handling for flavors (dark/light) and accents
- Theme changes require `chezmoi apply` to take effect

### Bash Auto-starts Fish

`dot_bashrc.tmpl` automatically launches Fish shell on interactive login:
```bash
if [[ $(ps --no-header --pid=$PPID --format=comm) != 'fish' \
   && -z ${BASH_EXECUTION_STRING} \
   && ${SHLVL} == 1 \
   && $- == *i* \
   && -x $(command -v fish) ]]; then
  shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
  exec fish $LOGIN_OPTION
fi
```

This means Bash is rarely used directly.

### Environment Variables

- User environment variables are loaded via `environment.d/*.conf` files
- They're sourced in Bash via the `bash_env` template
- A hash mechanism (`user_env_hash`) prevents redundant loads
- Changes to environment.d files require reloading or `chezmoi apply`

## Testing and Validation

### Quick Validation

After changes:
```sh
just apply
```

If something breaks:
```sh
just reset
```

### Specific Tool Validation

**Fish:**
```sh
fish -c "echo 'Fish config loaded'"
```

**Neovim:**
```sh
nvim --headless +quit && echo "Neovim config valid"
```

**Kitty:**
```sh
kitty --debug-config
```

**Git:**
```sh
git config --list
```

## Dependencies

This dotfiles repository expects:
- Arch Linux environment
- Packages from [razor-x/archrc](https://github.com/razor-x/archrc)
- XDG environment variables from archrc's `pam_env.conf`
- chezmoi installed
- just installed
- watchexec (for `just watch`)

**Key tools configured:**
- Fish shell (with Fisher, Tide, fzf.fish, fifc, git plugin)
- Neovim (with lazy.nvim, mini.nvim, smart-splits, LSP)
- Kitty terminal
- Zellij multiplexer
- Yazi file manager
- Git, SSH, GPG
- Atuin (shell history)
- bat, eza, ripgrep, tealdeer, mise
- GitHub CLI (gh)
- Broot, navi

## Project-Specific Context

### Purpose

Personal dotfiles for user land configuration on Arch Linux systems. Designed for:
- Consistent environment across multiple machines
- Version-controlled configuration
- Theme flexibility (especially Catppuccin)
- Integration with modern CLI tools

### Target Machines

Configuration is hostname-aware. Some features are only enabled on specific machines (see `.chezmoiignore`). Current known hostnames: "minto", "anny".

### Bootstrap Process

New machine setup is documented in README.md:
1. Initialize chezmoi: `chezmoi init --apply --source ~/config/dotfiles razor-x`
2. Reboot
3. Add SSH public key to GitHub
4. Update remote to SSH
5. Import GPG key
6. Add SSH passphrase
7. Login to Atuin
8. Add GitHub packages token
9. Final reboot

### Man Page

This repository has a man page generated from README.md:
```sh
man dotfiles
```

The generation is handled by `.chezmoiscripts/.man_from_readme.fish`.

## Workflow Tips

### Making Changes

1. Navigate to source directory: `dotfiles` (or `cd ~/config/dotfiles`)
2. Edit files in `home/` directory
3. Apply with `just apply` (or use `just watch` for auto-apply)
4. Test the changes
5. Commit: `git add <files> && git commit -m "message"`
6. Push: `git push`

### Adding New Configuration

**New tool config:**
1. Create directory under `home/dot_config/`
2. Use `exact_` prefix if you want exclusive management
3. Add config files (use `.tmpl` if they need templating)
4. Apply with `just apply`
5. Test the tool
6. Update this document if there are special considerations

**New template:**
1. Add to `home/.chezmoitemplates/`
2. Reference with `{{ template "name" . }}`
3. Test with `just apply`

**New external resource:**
1. Add entry to `home/.chezmoiexternal.yaml`
2. Include URL and sha256 checksum
3. Apply to fetch: `just apply`

**New script:**
1. Add to `home/.chezmoiscripts/`
2. Use `run_onchange_` prefix for conditional execution
3. Add hash comment for dependency tracking
4. Make executable
5. Test with `just apply`

### Debugging Templates

If a template fails to render:
```sh
chezmoi execute-template < file.tmpl
```

To see what would be applied:
```sh
chezmoi diff
```

To see the rendered content of a specific file:
```sh
chezmoi cat ~/.config/fish/config.fish
```

### Updating External Resources

1. Update URL in `.chezmoiexternal.yaml`
2. Download the file manually to get its hash:
   ```sh
   curl -L <url> | sha256sum
   ```
3. Update the checksum
4. Apply: `just apply`

## Common Tasks

### Change Theme

Edit `home/.chezmoi.yaml.tmpl`:
```yaml
data:
  theme: catppuccin  # or "default"
```

Then apply:
```sh
just apply
```

### Add Fish Plugin

Edit `home/dot_config/fish/fish_plugins`:
```
author/repo@commit-hash
```

Then apply (triggers `run_onchange_after_fish.fish.tmpl`):
```sh
just apply
```

### Add Neovim Plugin

Edit `home/dot_config/exact_nvim/lua/config/plugins.lua`:
```lua
{ "author/plugin-name", opts = {} }
```

Then apply and open Neovim:
```sh
just apply
nvim  # Lazy will auto-install
```

### Update Git Configuration

Edit `home/dot_config/exact_git/config` (remember: use **tabs** for indentation).

For user info, edit `home/dot_config/exact_git/user.tmpl`.

Then apply:
```sh
just apply
```

### Add Environment Variable

Create or edit a file in `home/dot_config/exact_environment.d/`:
```sh
# home/dot_config/exact_environment.d/99-myvar.conf.tmpl
MYVAR=value
```

Then apply:
```sh
just apply
```

Variables are loaded on next shell start or via the `bash_env` template mechanism.

## When Working With This Repository

### Read Before Modifying

- Always check `.editorconfig` for indentation rules
- Review existing files for patterns before adding new ones
- Check `.chezmoiignore` to understand what's not managed
- Verify hostname conditions if config seems missing

### Test Changes Thoroughly

- Use `just watch` during development for rapid iteration
- Test on actual target machine, not just in source directory
- Verify scripts execute correctly (check for error messages)
- Ensure templates render properly with `chezmoi cat <file>`

### Keep Documentation Updated

- Update this AGENTS.md when adding new patterns or gotchas
- Update README.md for user-facing changes
- Add comments in complex templates
- Document non-obvious design decisions

### Respect Existing Patterns

- Follow commit message style
- Use existing template helpers when available
- Match indentation and file organization
- Maintain the theme system consistency

## Resources

- [chezmoi documentation](https://www.chezmoi.io/)
- [just command runner](https://github.com/casey/just)
- [Go template syntax](https://pkg.go.dev/text/template)
- [Catppuccin theme](https://github.com/catppuccin/catppuccin)
- User's Arch Linux config: [razor-x/archrc](https://github.com/razor-x/archrc)

---

**Last Updated:** Generated automatically on first creation. Update manually when significant changes occur.
