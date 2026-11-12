# Firstmate vessels

```sh
firstmate /path/to/anchor [Pi arguments...]
firstmate ~/seam --sail-to desktop
firstmate ~/seam --scuttle
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

To send a vessel before this machine goes offline, run `--sail-to HARBOR` as the only option after the anchor, from a separate terminal outside the source Pi session.
This delegates to core's `sail --to`, waits for acknowledgement and exits without starting Pi or offering initialization.
A failed push returns the core error and does not print a success message.
The source must stay online until success; the destination then starts locally without pulling from it.

`--scuttle` requires typing `SCUTTLE` to permanently discard the local vessel, repositories, uncommitted work and session history.
Run it from a separate terminal; it stops local work first and exits without launching Pi or offering initialization.
Cancelling or reaching end-of-input performs no core action.
Outside repositories and other harbors are not removed; directory permissions are repaired without chmodding shared hardlinked files.

## Caller policy

Core owns the vessel layout, portable runtime environment, discovery, SSH/rsync transfer and path validation; the wrapper does not set the shared directory variables.
Pi preferences, authentication and installed tools stay on the host.
The launcher names the main conversation `captain` with `--name captain` and continues it with `--continue`, separately from worker history.
Its existing `$vessel/pi/primary` storage path is retained so prior history is not moved or abandoned.
Session arguments are defaults, not a path-validation gate; explicitly supplied Pi options can override them.

In normal launch mode this wrapper starts Pi directly with the personal `--approve` flag and leaves its arguments unchanged.
Core clears ambient routing; Firstmate's ordinary tmux backend creates its detached worker session when needed.
`environment.d/50-firstmate.conf` defines the personal preference names in `FM_WORKER_ENV_FORWARD`.
Core appends its required portable names to that same list; empty or unset no longer disables core forwarding.
The wrapper chooses `--agent pi` when asking core to initialize a vessel.
Core records the No-mistakes choice and owns the configuration write; the launcher neither reads the initialization JSON nor writes tool configuration.
Existing preferences are not rewritten.
Background work can outlive the visible interface.
Core stops known source work before sailing and asks the existing source Pi agent to resolve unfamiliar processes; an unconfirmed stop prevents copying.

The wrapper uses the Nono `firstmate` profile; sandbox policy is managed separately.
No sandbox policy or installed home files are deployed by these changes.
No migration of unrelated old homes or backend fallback is implemented.

## Verification

Environment and forwarding coverage lives in core's `tests/fm-anchor.test.sh`.
This minimal launcher has no separate test suite; interactive Pi/Nono and worker behavior are checked during local use.
