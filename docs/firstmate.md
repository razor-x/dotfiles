# Firstmate wrapper

Daily use:

```sh
firstmate ~/seam
```

The argument is an existing anchor directory, not a collection of repositories.
The wrapper resolves its absolute physical path, replaces inherited `FM_ANCHOR`
and `FM_HOME`, and exports only those two path variables before executing
Firstmate's `bin/fm-firstmate.sh`.
Arguments, process signals, and exit status pass through `exec`.
It does not create capsule directories, inspect projects, read port records,
prompt, transfer files, or change sandbox policy.

Firstmate core owns all remaining paths, docking, startup, and recovery.
The `fm-dock` delegator exposes the core command on the noninteractive SSH PATH;
it does not implement a second docking protocol.
Both delegators resolve the installed core from `XDG_DATA_HOME/firstmate`, falling
back to `~/.local/share/firstmate`.

## Deployment order

1. Land and install the companion Firstmate core change first.
1. Review and deploy the narrow sandbox capabilities outside the agent session.
1. Land and apply this wrapper change.

Do not deploy this wrapper against an older core or an unreviewed sandbox
profile.
The old wrapper's broad anchor grant is deliberately not retained.
Existing unlanded work requires the core's documented migration procedure;
neither delegator migrates or deletes it.

## Verification

`just check-firstmate` runs the fake-entrypoint wrapper contracts.
`just check-tools` also includes them in the tools test collection.
The tests use temporary directories and never launch a real user session.

For combined validation, run the core's protocol test with this wrapper path:

```sh
FM_DOCK_WRAPPER="$PWD/home/dot_local/exact_bin/executable_firstmate" \
  python3 ../firstmate/tests/fm-docking.py \
  Docking.test_wrapper_launches_docked_destination_and_reverses
```

The combined test uses fake SSH, rsync, the sandbox command and Pi, while running
the real core launcher and docking protocol in private fixture namespaces.
The core's separate token-free Pi guard verifies cooperative shutdown through a
real private RPC session without a model prompt.
