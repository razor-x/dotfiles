# FirstMate environment handoff: reproducible integration issues

Date: 2026-11-09

## Scope

This handoff contains issues reproducible from clean state. It excludes stale state caused by the FirstMate home relocation, pre-existing linked worktrees, exited-session metadata, and expected container restrictions.

## No-mistakes defaults conflict with the intended nono environment

From clean configuration, no-mistakes can select two paths that are incompatible with the intended sandbox:

- Fetching a trusted GitHub branch over SSH requires the deliberately protected `~/.ssh/known_hosts`.
- Auto-selecting OpenCode requires writing global OpenCode state outside the granted paths.

The successful operational configuration used GitHub HTTPS with the command-scoped `gh auth git-credential` helper and selected `agent: pi`.

### Required outcome

Make the supported sandbox configuration explicit and home-local: GitHub fetches use HTTPS with the `gh` credential helper, and validation uses Pi. Preserve project remotes and global Git configuration unchanged. Do not broaden nono access to SSH, OpenCode state, or container runtimes for these workflows.

### Completion criteria

- `no-mistakes doctor` passes in a fresh FirstMate home without repository-by-repository repair.
- Trusted-branch fetches succeed without reading `~/.ssh`.
- Validation starts with Pi without probing or writing OpenCode state.
- Project remotes and global Git configuration remain unchanged.

## Known constraint, not a FirstMate defect

Container-backed Connect integration tests cannot run inside the current nono profile because rootless Podman requires runtime, namespace, and `/proc` authority beyond a narrow filesystem grant. Workers should run container-independent checks locally and leave container integration tests to CI.

## Explicitly excluded

- Missing `data/`, backlog, and project records after changing FirstMate homes.
- Stale no-mistakes gate URLs containing the previous home path.
- Existing ENG-4148 branches already attached to linked worktrees.
- Automatic adoption of existing PR worktrees.
