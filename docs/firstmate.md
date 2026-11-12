# Firstmate vessels

```sh
firstmate /path/to/anchor [Pi arguments...]
```

Use an existing directory at the same physical path on every harbor.
At an empty harbor, the launcher first asks whether to sail a vessel here and prompts only for its source harbor.
Declining that offer leads to a separate confirmation before initializing a new vessel; failed or cancelled sailing never falls through to initialization.
For a known vessel, core discovers its harbor and brings it here when needed before starting Pi directly in the current terminal pane under Nono.
Only workers run in tmux.
A vessel is the working environment, not a ship task.
Zellij-specific Firstmate launch integration is removed; unrelated desktop Zellij preferences are unchanged.

Install the matching core `bin/fm-anchor.sh` before applying this wrapper.
Core is resolved from `${XDG_DATA_HOME:-$HOME/.local/share}/firstmate`, the installed core rather than the development working copy.
The core vessel guide owns the records, discovery, transfer prerequisites and launch contract.

## Caller policy

Core owns the vessel layout, portable runtime environment, discovery, SSH/rsync transfer and path validation; the wrapper does not set the shared directory variables.
Pi preferences, authentication and installed tools stay on the host.
The launcher selects `$vessel/pi/primary` with `--session-dir` and `--continue`, so normal launches continue the latest primary conversation separately from worker history.
Session arguments are defaults, not a path-validation gate; explicitly supplied Pi options can override them.

This wrapper starts Pi directly with the personal `--approve` flag and leaves its arguments unchanged.
Core clears ambient routing; Firstmate's ordinary tmux backend creates its detached worker session when needed.
`environment.d/50-firstmate.conf` defines the personal preference names in `FM_WORKER_ENV_FORWARD`.
Core appends its required portable names to that same list; empty or unset no longer disables core forwarding.
The wrapper chooses `--agent pi` when asking core to initialize a vessel.
Core records the No-mistakes choice and owns the configuration write; the launcher neither reads the initialization JSON nor writes tool configuration.
Existing preferences are not rewritten.
Background work can still outlive the visible interface; stop all source work manually before sailing.

The wrapper uses the Nono `firstmate` profile; sandbox policy is managed separately.
No sandbox policy or installed home files are deployed by these changes.
No automatic stopping, migration of unrelated old homes or backend fallback is implemented.

## Verification

Environment and forwarding coverage lives in core's `tests/fm-anchor.test.sh`.
This minimal launcher has no separate test suite; interactive Pi/Nono and worker behavior are checked during local use.
