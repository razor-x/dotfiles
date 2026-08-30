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
1. Assume the user will apply the changes. When live synchronization would
   help, ask the user to run `just watch` in their own terminal and continue
   working against the repository.

For Pi configuration, follow `home/dot_config/pi/AGENTS.md` before editing its
instructions, local extension, or local skills.
