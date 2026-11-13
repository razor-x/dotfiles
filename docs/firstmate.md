# Firstmate vessels

```fish
firstmate /path/to/anchor [--vessel NAME] [Pi arguments...]
firstmate ~/seam --vessel red
firstmate ~/seam --vessel red --sail-to desktop
firstmate ~/seam --vessel red --scuttle
```

`firstmate` is an autoloaded Fish function from the dedicated local `~/.local/share/plugin/firstmate` plugin, with a matching completion file; it replaces the executable launcher.
The plugin follows Delve's `functions/` and `completions/` layout, is registered in `fish_plugins`, and participates in the Fish plugin update hash.
The default vessel is `flagship`.
Each vessel lives at `<anchor>/.firstmate/NAME/`, with its `NAME.json` record and `NAME.lock` alongside it inside `.firstmate/`.
Vessels have separate working repositories, conversations, tool state and active harbors; operating on one does not operate on another.
Use an existing directory at the same physical path on every harbor.
After the anchor, `--vessel` completes locally registered names, including inactive caches, without SSH or writes; new names may also be typed directly.
At an empty harbor, the launcher first asks whether to sail a vessel here and prompts only for its source harbor.
Declining that offer leads to a separate confirmation before initializing a new vessel; failed or cancelled sailing never falls through to initialization.
For a known vessel, core discovers its harbor and brings it here when needed before starting Pi directly in the current terminal pane under Nono.
Only workers run in tmux.
A vessel is the working environment, not a ship task.
Zellij-specific Firstmate launch integration is removed; unrelated desktop Zellij preferences are unchanged.

Install the matching named-vessel core `bin/fm-anchor.sh` before applying the Fish integration.
Core is resolved from `${XDG_DATA_HOME:-$HOME/.local/share}/firstmate`, the installed core rather than the development working copy.
The core vessel guide owns the records, discovery, transfer prerequisites and launch contract.

To send a vessel before this machine goes offline, run `--sail-to HARBOR`, optionally with `--vessel NAME` but without Pi arguments, from a separate terminal outside the source Pi session.
This delegates to core's `sail --to`, waits for acknowledgement and exits without starting Pi or offering initialization.
A failed push returns the core error and does not print a success message.
The source must stay online until success; the destination then starts locally without pulling from it.

`--scuttle` requires typing `SCUTTLE` to permanently discard the local vessel, repositories, uncommitted work and session history.
Run it from a separate terminal; it stops local work first and exits without launching Pi or offering initialization.
Cancelling or reaching end-of-input performs no core action.
Other named vessels, outside repositories and other harbors are not removed; directory permissions are repaired without chmodding shared hardlinked files.

## Caller policy

Core owns the vessel layout, portable runtime environment, discovery, SSH/rsync transfer and path validation; the wrapper does not set the shared directory variables.
Pi preferences, authentication and installed tools stay on the host.
The launcher names the main conversation `captain` with `--name captain` and continues it with `--continue`, separately from worker history.
Each named vessel keeps its own history at `$vessel/pi/primary`.
Session arguments are defaults, not a path-validation gate; explicitly supplied Pi options can override them.

In normal launch mode the function starts Pi directly with the personal `--approve` flag and leaves its arguments unchanged after removing launcher options.
Use `--` before literal Pi options that overlap launcher options.
It returns the child exit status without replacing the interactive Fish shell or changing its environment.
Core clears ambient routing; Firstmate's ordinary tmux backend creates its detached worker session when needed.
`environment.d/50-firstmate.conf` defines the personal preference names in `FM_WORKER_ENV_FORWARD`.
Core appends its required portable names to that same list; empty or unset no longer disables core forwarding.
The wrapper chooses `--agent pi` when asking core to initialize a vessel.
Core records the No-mistakes choice and owns the configuration write; the launcher neither reads the initialization JSON nor writes tool configuration.
Existing preferences are not rewritten.
Background work can outlive the visible interface.
Core stops known source work before sailing and asks the existing source Pi agent to resolve unfamiliar processes; an unconfirmed stop prevents copying.

The function uses the Nono `firstmate` profile and grants only the selected payload directory, `--allow-file` for its coordination lock and `--read-file` for its JSON record.
It does not grant access to the whole `.firstmate/` container or other vessels.
Sandbox profiles are managed separately.
No sandbox policy or installed home files are deployed by these changes.

## Verification

Environment and forwarding coverage lives in core's `tests/fm-anchor.test.sh`.
The Fish launcher has no separate persistent test suite.
Disposable native Fish probes cover vessel completion, argument/status preservation, confirmations, cancellation, end-of-input and file-specific Nono arguments.
A disposable real-Nono probe verifies the selected record and lock grants, refusal when either grant is omitted, and denial of sibling vessel records.
Interactive Pi/Nono and worker behavior still require verification in a terminal with PTY access.
