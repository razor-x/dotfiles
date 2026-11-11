# Local Firstmate vessels

```sh
firstmate /path/to/anchor [Pi arguments...]
```

Use an existing directory and a fresh `.firstmate` vessel.
The first launch asks before anchoring it; later launches check its recorded harbor and paths before starting Pi directly in the current terminal pane under Nono.
Only workers run in tmux.
A vessel is the working environment, not a ship task.
Zellij-specific Firstmate launch integration is removed; unrelated desktop Zellij preferences are unchanged.

Install the matching core `bin/fm-anchor.sh` before applying this wrapper.
Core is resolved from `${XDG_DATA_HOME:-$HOME/.local/share}/firstmate`, the installed core rather than the development working copy.
The core vessel guide owns the local metadata and gate contract.

## Caller policy

`FM_HOME` is the vessel itself, with `config/`, `data/`, `state/` and `projects/` below it.
Treehouse worktrees, Pi conversations, No-mistakes/Lavish state, tmux sockets and cache also use vessel-contained defaults.
Conflicting inherited home/anchor settings and paths outside the vessel refuse rather than being silently relocated.
Pi preferences, authentication and installed tools stay on the host.
Pi session options require an absolute vessel-contained path, not an unscoped session ID.

This wrapper starts Pi directly with the personal `--approve` flag and leaves its arguments unchanged.
It clears ambient multiplexer routing; Firstmate's ordinary tmux backend creates its detached worker session when needed, using the vessel's private `TMUX_TMPDIR`.
The worker forwarding default applies only when unset; explicit lists and explicit empty values are preserved.
New No-mistakes homes default to `agent: pi`; existing preferences are not rewritten.
`NM_TEST_START_DAEMON=1` is the caller's default for the verified No-mistakes 1.111+ descendant daemon mode, avoiding external systemd startup.
Background work can still outlive the visible interface; stopping it is manual in this stage.

The wrapper uses the Nono `firstmate` profile; sandbox policy is managed separately.
No sandbox policy or installed home files are deployed by these changes.
No transfer, automatic stopping, migration of old homes or backend fallback is implemented.

## Verification

Run `just check-firstmate` or `just check-tools`.
For real core integration, set `FIRSTMATE_TEST_CORE=/path/to/firstmate/bin/fm-anchor.sh` when running the tests.
The primary-launch regression checks a direct Pi command and exact arguments, without starting a real user session.
