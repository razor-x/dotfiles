# Firstmate ship integration

```sh
firstmate ~/root [Pi arguments...]
```

Linux-only. The argument is an existing anchor directory, not a collection of
repositories to scan. The portable ship is `<anchor>/.firstmate`; its control
record and advisory lock remain outside it. Absolute physical anchor paths must
match between harbors.

## Responsibilities

The local `firstmate` script resolves the physical anchor and calls the installed
core's `bin/fm-board.sh`. Core owns compatibility/containment checks, explicit
initialization, discovery/docking questions and the full-environment lease.
Core never chooses this wrapper's personal runtime flags or forwarding list.

The wrapper owns the Pi/Zellij/Nono invocation:

- Requires Pi 1.5.0+, Zellij 0.45.1+ and Nono 0.81.0+; incompatible tools fail
  rather than selecting another stack.
- Supplies `FM_HOME=<ship>/home` and defaults `FM_BACKEND` to `zellij`, without
  changing an explicitly supplied backend.
- Chooses a fresh private Zellij session unless the caller supplies one. Core
  rejects a session name that would alias existing task endpoints or an unleased
  live server.
- Builds a literal in-memory Zellij layout for Pi. It writes no ship files before
  core has resolved ownership or confirmed initialization. Arguments are encoded
  as KDL strings, not shell commands.
- Keeps the existing personal Pi defaults (`--approve`, optional version-check
  suppression and OSC52) here, with supplied environment settings preserved.
- Leaves Pi preferences/authentication in the host's normal agent directory;
  `PI_CODING_AGENT_SESSION_DIR` directs conversations into `<ship>/pi/sessions`.
- Uses ship-contained defaults for Treehouse worktrees, No-mistakes state,
  task/launch temporary directories (`FM_TASK_TMP_ROOT`), Lavish state and Zellij sockets/data. Existing selectors are passed to core for
  compatibility checks, not silently relocated.
- Deliberately scopes `XDG_CACHE_HOME` to `<ship>/cache` because Zellij stores
  resurrection/session metadata there. Host configuration and authentication
  directories are not copied into the ship.
- Defaults `NM_TEST_START_DAEMON=1` only when unset, keeping the private
  No-mistakes daemon inside the leased process tree instead of systemd. Core
  requires No-mistakes 1.111.0+ and rejects incompatible supplied settings rather
  than replacing them.
- Applies a default `FM_WORKER_ENV_FORWARD` only when unset. An explicit list or
  explicit empty value is preserved. Core supplies no forwarding defaults.
- Uses Nono's existing `firstmate` profile, reads the shared code checkout and
  grants the same ship directory the original integration used. The old broad
  anchor grant is not retained. No profile source is changed or deployed.

Inherited `FM_ANCHOR` or `FM_HOME` conflicting with the requested anchor is an
error. Explicit `--session`/`--session-dir` arguments must use absolute paths
inside the ship; unscoped session IDs are unsupported rather than searched in
host state. Ordinary Pi usage and ordinary Firstmate home selection are unchanged.

`fm-dock` and `fm-undock` are external core delegators, including the noninteractive
SSH peer entrypoint. They contain no second transport protocol or personal
runtime policy. All three commands resolve core from `XDG_DATA_HOME/firstmate`,
falling back to `~/.local/share/firstmate`.

## Deployment order

1. Land and install the companion Firstmate core interfaces first.
1. Review the existing sandbox configuration outside the agent session.
1. Land and apply this caller integration.

Do not apply this wrapper to an older core. Neither wrapper nor core automatically
converts existing ordinary homes, rewrites application metadata, migrates tasks
or deletes unlanded repositories. Keep existing copies for deliberate manual
reconciliation.

A crashed lifetime guard leaves a durable fence. Core can recover it only after
a different kernel boot identity proves old writers cannot survive; a missing PID
or free lock is not same-boot recovery authority.

## Verification

`just check-firstmate` checks caller policy, literal arguments, private session
storage, version refusal, physical/conflicting anchors, exec/signals/status and
external transport delegation with temporary fake entrypoints.
`just check-tools` includes the same tests in the tools collection.
When Zellij is installed, they also send the generated layout to its real
`setup --check` parser in private configuration/cache/data/socket directories,
including control-character and Unicode arguments.
These tests never launch a real user session or apply sandbox policy.
