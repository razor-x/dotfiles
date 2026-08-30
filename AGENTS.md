# Repository guide

## Chezmoi source

This repository is a chezmoi source tree; `.chezmoiroot` maps `home/` to the
managed home directory.

- Keep inspection and verification of managed configuration inside this
  repository. Treat files under `home/` as authoritative; installed copies
  under `$HOME` are outside the working boundary.
- For sandbox capabilities, inspect
  `home/dot_config/nono/exact_profiles/`—starting with the active profile and
  the profiles it extends—to determine allowed paths instead of probing paths
  outside the repository.
- Preserve chezmoi source attributes in names such as `dot_`, `exact_`,
  `executable_`, and `symlink_`; follow neighboring files for the intended
  pattern.
- Treat `*.tmpl` files as Go templates rendered by chezmoi.
- When removing a managed source outside an `exact_` directory, add its target
  path to `home/.chezmoiremove`.
- Regenerate `bootstrap.sh` with `just generate`.

## Workflow

1. Make the smallest source change that covers the request.
1. Run `just format` after editing supported file types.
1. Run `just check`; every reported failure is fixed or called out before
   completion.
1. Assume the user will apply managed changes. When live synchronization would
   help, ask the user to run `just watch` in their own terminal. Pi
   self-modification follows its nested on-the-fly synchronization workflow.

## Major configurations

### Neovim

- Read `home/dot_config/exact_nvim/README.md` before changing Neovim; its
  architecture, typing, and plugin-global registration rules are completion
  criteria.
- Keep `exact_lua/exact_plugins/*.lua` organized by interface. Preserve the
  standalone path in `init.lua`, where the generated `dotfiles` module may be
  absent.
- Update `doc/dotfiles.txt` with user-facing mapping changes. Treat
  `.lazy-lock.json` as pinned input and change it only for an explicit plugin
  upgrade.

### Pi

- Follow `home/dot_config/pi/AGENTS.md` before editing Pi instructions, local
  extensions, or local skills.
- Put installed extension packages in `exact_npm`; put custom TypeScript in
  `extensions/exact_local` and custom skills in `skills/exact_local`. Keep
  package manifests and lockfiles together.
- Validate custom extension changes with its existing npm scripts; the root
  `just check` includes its full check.

### Kitty

- Keep `kitty.conf.tmpl` as the composition root: aliases, includes, theme, and
  font template data. Put ordinary preferences in `preferences.conf.tmpl`,
  keyboard mappings in `keymap.conf`, mouse mappings in `mouse.conf`, and the
  modal keyboard layer in `oneshot.conf`.
- Keep equivalent actions in `keymap.conf` and `oneshot.conf` behaviorally
  aligned. Search Neovim and Fish before changing shared terminal chords or
  smart-splits integration.
- Treat `current-theme.conf` and external kitten files as generated. Local
  kittens are typed Python entry points using Kitty's `main` and
  `@result_handler` protocol.

### Fish

- Keep shell startup policy in `home/dot_config/fish/config.fish`. Put
  autoloaded integrations in
  `home/dot_local/share/exact_plugin/exact_fish/exact_conf.d/` and one
  autoloadable function per matching filename in `exact_functions/`.
- Guard interactive integrations with `status is-interactive`. Use `.tmpl`
  only when chezmoi must render data or command output.
- Keep third-party and local plugin declarations in
  `home/dot_config/fish/fish_plugins`; local Fish code belongs to the `fish`
  plugin tree above.

Terminal keybindings span Neovim, Kitty, and Fish. Before assigning or changing
one, search all three configurations for the chord and preserve intentional
parity or conflict handling.
