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

Core owns the vessel layout, portable runtime environment and path validation; the wrapper does not set the shared directory variables.
Pi preferences, authentication and installed tools stay on the host.
Pi session options require an absolute vessel-contained path, not an unscoped session ID.

This wrapper starts Pi directly with the personal `--approve` flag and leaves its arguments unchanged.
Core clears ambient routing; Firstmate's ordinary tmux backend creates its detached worker session when needed.
The wrapper adds its personal preference names through `FM_WORKER_ENV_FORWARD_DEFAULTS`; core combines those with its portable forwarding defaults.
An explicit `FM_WORKER_ENV_FORWARD`, including empty, overrides both layers.
New No-mistakes homes default to `agent: pi`; the wrapper gets the selected settings location from core's initialization result rather than duplicating its layout.
Existing preferences are not rewritten.
Background work can still outlive the visible interface; stopping it is manual in this stage.

The wrapper uses the Nono `firstmate` profile; sandbox policy is managed separately.
No sandbox policy or installed home files are deployed by these changes.
No transfer, automatic stopping, migration of old homes or backend fallback is implemented.

## Verification

Environment and forwarding coverage lives in core's `tests/fm-anchor.test.sh`.
This minimal launcher has no separate test suite; interactive Pi/Nono and worker behavior are checked during local use.
