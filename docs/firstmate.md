# Firstmate vessel integration

```sh
firstmate ~/root [Pi arguments...]
```

Linux-only, using tmux. The argument is an existing physical anchor directory.
The vessel is `<anchor>/.firstmate`, distinct from a **ship task** (an implementation
worker task). Its control record and advisory lock remain outside the vessel.
Absolute physical anchor paths must match between harbors.

Zellij boarding is unsupported. Existing Zellij patches and dormant launch code
remain for a separate cleanup; they are not an alternative runtime or fallback.
An existing Zellij vessel is refused, never automatically converted.

## Responsibilities

The local `firstmate` script resolves the physical anchor and calls the installed
core's `bin/fm-board.sh`. Core owns compatibility/containment checks, explicit
initialization, discovery/docking questions and the full-environment lease.
Core never chooses this wrapper's personal runtime flags or forwarding list.

The wrapper owns the Pi/tmux/Nono invocation:

- Requires Pi 1.5.0+, tmux 3.2+ and Nono 0.81.0+; incompatible tools fail without
  selecting another runtime. The caller defaults `FM_BACKEND` to `tmux` and
  rejects other selections.
- Supplies `FM_HOME=<vessel>/home` and chooses a fresh private `FM_TMUX_SESSION`
  unless supplied. Core refuses old endpoint aliases and unleased live servers.
- Uses vessel-contained `TMUX_TMPDIR` and clears ambient host multiplexer routing.
  No host server is adopted.
- Supplies direct Pi argv to `new-session`, without shell-command encoding.
  Terminal semicolons are escaped for tmux's command parser so Pi receives the
  original argument, including an existing backslash before the semicolon.
- Writes no vessel files before core resolves ownership or confirms initialization.
- Keeps personal Pi defaults (`--approve`, optional version-check suppression and
  OSC52) here, preserving supplied environment settings.
- Leaves Pi preferences/authentication in the host agent directory;
  `PI_CODING_AGENT_SESSION_DIR` directs conversations into `<vessel>/pi/sessions`.
- Uses contained defaults for Treehouse worktrees, No-mistakes state,
  task/launch temporary directories (`FM_TASK_TMP_ROOT`), Lavish state and cache.
  Existing selectors go to core for compatibility checks, not silent relocation.
- Defaults `NM_TEST_START_DAEMON=1` only when unset, keeping the private No-mistakes
  daemon inside the leased process tree instead of systemd. Core requires
  No-mistakes 1.111.0+ and refuses incompatible supplied settings.
- Applies default `FM_WORKER_ENV_FORWARD` only when unset. Explicit lists and
  explicit empty values are preserved. Core supplies no forwarding defaults.
- Uses Nono's existing `firstmate` profile, reads shared code and grants the
  vessel directory. The old broad anchor grant is not retained. No profile is
  changed or deployed.

Inherited `FM_ANCHOR` or `FM_HOME` conflicting with the requested anchor is an
error. Explicit `--session`/`--session-dir` arguments must be absolute paths inside
the vessel; unscoped session IDs are unsupported, not searched in host state.
Ordinary Pi usage and ordinary Firstmate home selection are unchanged.

`fm-dock` and `fm-undock` externally delegate to core, including its noninteractive
SSH peer entrypoint. They contain no second transport protocol or personal policy.
All three commands resolve core from `XDG_DATA_HOME/firstmate`, falling back to
`~/.local/share/firstmate`.

## Deployment order

1. Land and install the companion core interfaces first.
1. Review existing sandbox configuration outside the agent session.
1. Land and apply this caller integration.

Do not apply this wrapper to an older core. Neither wrapper nor core converts
ordinary homes or existing vessels, rewrites application metadata, migrates tasks
or deletes unlanded repositories. Keep copies for deliberate manual reconciliation.

A crashed guard leaves a durable fence. Core recovers it only after a changed
kernel boot identity proves old writers cannot survive; a missing PID or free
lock is not same-boot recovery authority.

## Verification

`just check-firstmate` exercises caller policy, literal arguments, private session
storage, tmux-only selection, version refusal, physical/conflicting anchors,
exec/signals/status and transport delegation with temporary fake entrypoints.
`just check-tools` includes the same cases.
When tmux is installed, a private pane-free daemon checks terminal-semicolon
arguments through its real command parser, without allocating a PTY or running Pi.
Dormant Zellij parser coverage is skipped, not maintained as supported behavior.
These tests never launch a real user session or apply sandbox policy.
