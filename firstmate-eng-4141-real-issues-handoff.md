# FirstMate environment handoff: reproducible integration issues

Date: 2026-11-09

## Scope

This handoff contains issues reproducible from clean state. It excludes stale state caused by the FirstMate home relocation, pre-existing linked worktrees, exited-session metadata, and expected container restrictions.

## 1. Zellij backend startup does not establish a usable interactive session

The launcher pins `FM_BACKEND=zellij` and a project-local `ZELLIJ_SOCKET_DIR`, but it can start FirstMate without a live Zellij session. Creating the missing session in the background is not safe for TUI workers: a worker launched before a real client established terminal dimensions rendered at one column, could not be classified, and could not receive a proven composer delivery.

A persistent attached client created before relaunch produced a normally sized replacement worker. This establishes the startup sequence as the cause; the attached tmux client was a diagnostic workaround, not a suitable product contract.

### Required outcome

The integration that pins Zellij must own its startup preconditions. Prefer launching or attaching Zellij interactively before starting the primary FirstMate process, so the primary and workers share a naturally sized session. Do not silently fall back to another backend.

Before admitting a worker, reject a session whose terminal geometry is not usable. The final design must not require an unrelated hidden tmux client to keep Zellij healthy.

### Completion criteria

- A fresh project-local FirstMate home can start with no existing Zellij session.
- The primary process enters a correctly sized Zellij session before workers launch.
- A newly launched Pi worker renders at normal width and supports state classification and proven composer delivery.
- No keeper tmux session or synthetic permanently attached client is required.

## 2. Zellij 0.45 empty-tab recovery omits normal Zellij chrome

The local empty-tab workaround creates a shell pane when `new-tab` returns no terminal pane. A Zellij tab's top tab bar and bottom status bar are plugin panes, so adding only the shell leaves the worker tab without normal Zellij UI.

The patch at `firstmate-zellij-045-empty-tab.patch` now requests the built-in `default` layout when creating task tabs:

```sh
zellij action new-tab --layout default ...
```

FirstMate already filters for non-plugin panes and targets the worker terminal by pane ID, so the tab and status plugins should not affect steering or capture.

### Completion criteria

- New task tabs contain the default tab bar, one worker terminal, and the status bar.
- FirstMate records and targets only the non-plugin worker pane.
- Pane capture and steering exclude plugin output.

## 3. No-mistakes defaults conflict with the intended nono environment

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
- Exited Zellij session metadata from previous homes or runs.
- Automatic adoption of existing PR worktrees.
