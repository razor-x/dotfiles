# Agents: Dirty or Non-Default Primary-Worktree Promotion

Status: deferred feature specification\
Depends on: `agents-design.md` MVP\
Working feature name: transactional promotion

## 1. Purpose

The MVP promotes only the current persisted Pi session when it is running in a
clean primary worktree on the default branch. This feature extends promotion to
the cases that naturally arise after exploratory work has already begun:

- staged changes;
- unstaged changes;
- untracked files;
- a feature branch already checked out in the primary worktree;
- any supported combination of those states.

The user experience remains:

> “Make this a managed agent.”

The direct creation UX remains within the `/agents` command namespace. This
feature replaces the clean promotion strategy behind that UX when preflight
identifies supported dirty or non-default-primary-worktree state; it neither
requires a particular creation subcommand name nor adds another command
namespace.

After success, the current runtime continues from a derived Pi session in the
same Kitty tab, but now operates in a dedicated Worktrunk worktree containing
the same branch and filesystem state. The original source Pi session remains
available, as in MVP promotion.

This is a natural extension of the core promotion operation. It does not need
to be implemented in the MVP, provided the MVP already has:

- a promotion preflight/result abstraction;
- `provisioning` agent state;
- recoverable operation records;
- Pi session fork/switch separated from worktree creation;
- Kitty tab adoption as the final activation step.

## 2. Relationship to the MVP

Transactional promotion changes only the filesystem/branch preparation phase.
It does not change:

- managed-agent identity and flat resource ownership;
- the active-agent one-Pi-session/one-worktree ownership invariant and
  at-most-one live tab;
- the active-agent registry and resource schema;
- Pi session continuation;
- Kitty adoption;
- restoration;
- delegation ancestry;
- GitHub status or cleanup.

The core should expose promotion internally as:

```ts
interface PromotionStrategy {
  preflight(ctx: PromotionContext): Promise<PromotionPlan>;
  prepareTarget(plan: PromotionPlan): Promise<PreparedPromotion>;
  rollbackOrDescribeFailure(
    plan: PromotionPlan,
    error: unknown,
  ): Promise<RecoveryReport>;
}
```

The MVP implements `CleanDefaultBranchPromotion`. This feature adds
`TransactionalPromotion` without rewriting agent activation.

The strategy returns a verified target worktree, initial branch, and any
recovery artifacts. Normal activation then appends the canonical worktree and
owned initial-branch references independently to the agent's flat resource
list. The branch is the first checkout, not durable agent or worktree identity;
later switching leaves the worktree binding unchanged. Stashes and preservation
manifests remain operation-journal resources and are not a separate workspace
object.

Promotion uses fresh preflight observations, not the source agent's cached
status. When activation changes the durable resource list, it increments the
agent revision, invalidates the prior observation cache, and performs a full
post-activation observation.

### 2.1 Normative feature requirements

| ID    | Requirement                                                                                                                                                                                         |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TP-01 | Transactional promotion shall preserve source HEAD, Git index state, working-tree state, and untracked file bytes in the target worktree.                                                           |
| TP-02 | Transactional promotion shall support dirty default-branch sources, clean existing-feature sources, and dirty existing-feature sources.                                                             |
| TP-03 | Existing-feature promotion shall leave that branch checked out in exactly one worktree and shall return the primary worktree to its default branch.                                                 |
| TP-04 | The extension shall capture a durable recovery artifact and manifest before it releases a branch or removes changes from the source worktree.                                                       |
| TP-05 | The extension shall verify target state independently before it switches the Pi session or adopts the Kitty tab.                                                                                    |
| TP-06 | A promotion interrupted after its first mutation shall be discoverable and resumable or manually recoverable from its operation record.                                                             |
| TP-07 | Ignored files shall not be transferred unless a separately specified policy explicitly enables them.                                                                                                |
| TP-08 | Merge/rebase/conflict, detached-HEAD, unsupported submodule, and ambiguous branch-topology cases shall refuse before mutation.                                                                      |
| TP-09 | A captured stash shall not be dropped until the target is verified and the managed agent's Pi session is active.                                                                                    |
| TP-10 | Failure or verification mismatch shall preserve the stash, target worktree, and operation record rather than force-cleaning either worktree.                                                        |
| TP-11 | The existing clean/default MVP promotion path shall remain available and shall not incur stash/manifest complexity when unnecessary.                                                                |
| TP-12 | Transactional promotion shall reuse the MVP registry, Pi continuation, Kitty adoption, and Worktrunk adapters rather than introduce a second managed-agent model.                                   |
| TP-13 | Transactional promotion shall populate separate canonical-worktree and initial-branch resources, shall not make branch currentness durable identity, and shall not introduce a workspace aggregate. |
| TP-14 | Preflight and target verification shall use fresh adapter observations and shall never accept cached cleanliness or topology as safety evidence.                                                    |
| TP-15 | Successful activation shall invalidate observations tied to the prior agent revision/resource fingerprint and shall refresh the activated agent.                                                    |

## 3. Requirements

### 3.1 State preservation

After successful promotion, the target worktree must preserve:

- source branch HEAD;
- staged changes as staged;
- unstaged changes as unstaged;
- untracked file paths, bytes, and executable modes;
- renames and deletions as represented by Git;
- the current Pi-session history through the same fork/switch mechanism used by
  MVP promotion.

Ignored files are excluded by default. They remain the responsibility of
Worktrunk hooks or explicit `copy-ignored` configuration. The feature may later
offer an explicit ignored-file policy, but it must never silently copy secrets,
dependency trees, build products, or repositories nested inside the source.

Worktrunk hooks run as part of the adapter effect. They may perform normal
project setup and may request a later full refresh, but they do not apply
partial promotion transitions to the agent record.

### 3.2 Supported source cases

| Source branch    | Filesystem      | Target behavior                                    |
| ---------------- | --------------- | -------------------------------------------------- |
| default          | clean           | existing MVP path                                  |
| default          | dirty/untracked | create new branch/worktree, transfer state         |
| existing feature | clean           | move branch checkout from primary to new worktree  |
| existing feature | dirty/untracked | capture state, move branch checkout, restore state |

### 3.3 Refused source cases

The feature must refuse promotion when any of these are present:

- unresolved merge conflicts;
- merge, rebase, cherry-pick, revert, or bisect in progress;
- detached HEAD unless separately designed later;
- submodule working-tree changes;
- sparse-checkout or worktree configuration that cannot be reproduced safely;
- a target branch checked out in another non-primary worktree;
- a default branch that cannot be checked out in the primary worktree for
  existing-feature transfer;
- filesystem paths the current user cannot read;
- an actual non-persisted `pi --no-session` source;
- another active promotion transaction for the repository.

Refusal is non-mutating and reports the exact failed precondition.

## 4. Preservation manifest

Before the first mutation, capture a manifest:

```ts
type WorkingStateManifest = {
  sourceWorktree: string;
  sourceBranch: string;
  sourceHead: string;
  defaultBranch: string;

  stagedPatchSha256: string;
  unstagedPatchSha256: string;
  untracked: Array<{
    path: string;
    sha256: string;
    executable: boolean;
    size: number;
  }>;

  statusPorcelainV2: string;
};
```

The exact canonical patch-generation commands are an implementation choice,
but the source and target must use the same byte-producing method. Preserve
binary diffs. Sort untracked entries by raw Git path order, not locale.

The manifest is stored in the promotion operation record before capture or
branch movement begins.

## 5. Transaction state

```ts
type TransactionalPromotionRecord = {
  schemaVersion: 1;
  operationId: string;
  managedAgentId: string;
  phase:
    | "preflight"
    | "captured"
    | "source-clean"
    | "branch-released"
    | "worktree-created"
    | "state-applied"
    | "state-verified"
    | "pi-forked"
    | "activated"
    | "completed"
    | "recovery-required";

  sourceWorktree: string;
  sourceBranch: string;
  sourceHead: string;
  targetWorktree?: string;
  targetBranch: string;

  stashOid?: string;
  stashMarker?: string;
  sourcePiSession: string;
  destinationPiSession?: string;
  manifest: WorkingStateManifest;
  lastError?: string;
};
```

Each phase transition is atomically persisted before the next mutating step.
The record must contain object IDs and canonical paths, not volatile names such
as `stash@{0}` or Kitty tab numbers.

## 6. Capture mechanism

The recommended initial implementation uses a uniquely marked Git stash:

1. Generate an operation-specific marker.
1. Run `git stash push --include-untracked --message <marker>` in the primary
   worktree.
1. Resolve and store the created stash commit OID.
1. Verify the source worktree is clean.
1. Never refer to the captured state solely as `stash@{0}` after this point.

The stash is a recovery artifact, not merely temporary scratch data. Do not
drop it until target state has been independently verified and the Pi session
has successfully activated in the new worktree.

If no changes exist, skip stash creation and use the clean path.

## 7. Algorithms

### 7.1 Dirty default branch to new branch

```text
preflight
capture manifest
stash tracked + untracked state
verify primary is clean
wt switch --create <new-branch> --base=@ --no-cd
apply exact stash OID with --index in target worktree
verify target manifest equals source manifest
fork/switch Pi session to target cwd
adopt current Kitty tab
drop uniquely identified stash entry
complete transaction
```

The branch is created from the exact source HEAD recorded by the manifest. If
the default branch moves concurrently before creation, refuse or explicitly
create from the recorded commit; never silently use the new tip.

### 7.2 Clean existing feature branch in primary worktree

```text
preflight
record feature HEAD
switch primary worktree to default branch
wt switch <existing-feature-branch> --no-cd
verify target branch and HEAD
fork/switch Pi session to target cwd
adopt current Kitty tab
complete transaction
```

Git prevents a branch from being normally checked out in two worktrees. The
primary checkout must release the feature branch before Worktrunk creates its
dedicated worktree.

### 7.3 Dirty existing feature branch

```text
preflight
capture manifest
stash tracked + untracked state
verify primary is clean
switch primary worktree to default branch
wt switch <existing-feature-branch> --no-cd
apply exact stash OID with --index in target worktree
verify target manifest equals source manifest
fork/switch Pi session to target cwd
adopt current Kitty tab
drop uniquely identified stash entry
complete transaction
```

## 8. Verification

Promotion is not successful merely because `git stash apply` exits zero.

After applying state in the target:

1. verify target branch and HEAD;
1. recalculate staged patch hash;
1. recalculate unstaged patch hash;
1. recalculate untracked file manifest;
1. compare normalized porcelain status;
1. verify source primary worktree is clean and on its intended post-promotion
   branch;
1. only then fork/switch the Pi session.
1. after activation, commit the new durable agent resource revision and discard
   cache entries tied to the old fingerprint;
1. freshly observe the target agent and populate its new cache.

Any mismatch enters `recovery-required`. Keep both stash and target worktree.
Do not try to make the state look correct using reset, checkout, or clean.

## 9. Stash cleanup

After activation, locate the stash reflog entry whose object ID and marker both
match the transaction. Drop only that exact entry.

If it cannot be identified uniquely:

- leave it in place;
- mark the promotion successful with a cleanup warning;
- show the OID and marker;
- never drop a different entry based on position.

A redundant retained stash is preferable to lost work.

## 10. Failure and recovery behavior

### 10.1 Before source capture

No mutation has occurred. Report refusal/failure and delete the operation
record.

### 10.2 After stash, before target worktree

The source state is recoverable from the stash OID. The extension may offer:

- resume promotion;
- restore the stash into the source with `--index`;
- leave everything untouched for manual recovery.

Never automatically drop the stash.

### 10.3 After feature branch release

The primary worktree may now be on the default branch. Recovery UI must state
where the feature branch is checked out, whether a target worktree exists, and
where the captured stash lives. Do not attempt to re-check out the feature in
the primary while a target worktree holds it.

### 10.4 After partial stash apply

Retain:

- the target worktree with partial/conflicted state;
- the original stash;
- the operation record and source manifest.

Do not force-remove the target or reset it automatically. Offer explicit manual
recovery instructions or a later carefully designed repair operation.

### 10.5 After Pi fork but before activation

Retain the destination Pi JSONL file and target worktree. The next controller
can resume activation using the operation record. The original source Pi session
remains intact.

## 11. Concurrency

Only one promotion transaction may mutate a repository at a time. Acquire a
repository-scoped lock keyed by canonical Git common directory.

After acquiring the lock, repeat every preflight observation directly through
the adapters. A plan or observation cache created before locking is advisory
only.

The operation must detect concurrent changes to:

- source HEAD;
- source status;
- branch checkout topology;
- default branch;
- target branch existence;
- Worktrunk worktree list.

Any detected change aborts before the next mutation.

## 12. Security and command construction

- Invoke Git and Worktrunk with argument arrays.
- Treat branch names and paths as untrusted data.
- Never construct stash commands through a shell string.
- Never invoke `git clean`, `git reset --hard`, branch force deletion, or
  Worktrunk force options.
- Never include ignored files without an explicit future policy.
- Ensure operation records and manifests are user-readable only.
- Avoid placing file contents in transaction JSON; store hashes and paths.

## 13. Rejected approaches

### Temporary WIP commit

Rejected as the default because it changes visible branch history and requires
history rewriting or reset to recreate the original staged/unstaged state.

### Raw filesystem copy

Rejected because it does not reliably preserve Git index state, renames,
deletions, sparse behavior, or ignored-file policy and is difficult to verify.

### Duplicate forced checkout

Rejected because checking the same branch into two worktrees with force creates
ambiguous ownership and undermines Worktrunk's topology and cleanup guarantees.

### Delete-and-hope rollback

Rejected. Any partially applied target or retained stash is preserved until a
human selects a recovery action.

## 14. User interaction

Before mutation, show a concise plan:

```text
Promote this Pi session?

Source:  ~/src/shop (feature/checkout)
Target:  ~/src/shop.feature-checkout
State:   2 staged, 3 modified, 1 untracked

The primary worktree will switch to main. Your changes will be captured,
verified in the new worktree, and retained in a recovery stash until the target
Pi session is active there.
```

One confirmation covers the transaction. Recovery actions require separate
confirmation.

## 15. Acceptance criteria

1. Dirty default-branch promotion preserves staged, unstaged, and untracked
   state exactly in a new branch/worktree.
1. Clean existing-feature promotion leaves primary on default and feature in
   exactly one dedicated worktree.
1. Dirty existing-feature promotion preserves the exact working state and
   index after moving branch ownership.
1. The runtime continues from the derived Pi session in the same Kitty tab and
   new cwd only after target verification succeeds.
1. Original Pi source session remains available.
1. Ignored files are neither copied nor deleted.
1. A simulated crash at every transaction phase produces a discoverable
   operation record and retains every piece of user work.
1. A concurrent source edit aborts the transaction rather than moving an
   outdated snapshot.
1. A stash apply conflict never triggers reset, clean, force removal, or stash
   deletion.
1. Stash cleanup drops only the exact matching object/marker entry.
1. Merge/rebase/conflict/submodule cases refuse before mutation.
1. Existing MVP clean/default promotion continues to use its simpler path.
1. A stale cache claiming the primary worktree is clean cannot bypass fresh
   preflight refusal.
1. Successful promotion invalidates the old cache and repopulates observations
   for the new resource fingerprint.

## 16. Suggested implementation order

1. Extract MVP promotion behind `PromotionStrategy`.
1. Implement manifest creation and verification as pure/testable functions.
1. Implement stash capture with OID/marker tracking.
1. Add dirty default-branch promotion.
1. Add clean existing-feature branch transfer.
1. Combine them for dirty existing-feature transfer.
1. Add crash simulation and phase-by-phase recovery tests.
1. Only then expose transactional promotion as the default strategy when its
   preflight recognizes a supported advanced case.

## 17. Testing implications

Transactional promotion follows the shared
[testing strategy](agents-testing-strategy.md):

- manifest construction, verification, eligibility, and operation-phase
  transitions are pure Vitest tests;
- scripted fake Git and Worktrunk adapters simulate every capture/apply/result
  combination without touching a real repository;
- controlled promises interleave concurrent edits and promotion phases without
  sleeps or timing-dependent tests;
- a fault-injecting state store simulates interruption before and after each
  durable journal write;
- narrow temporary-directory tests cover manifest/stash metadata persistence
  and restart recovery, not real Worktrunk integration;
- real dirty-worktree transfer remains a manual acceptance scenario.

## 18. References

- [Testing strategy](agents-testing-strategy.md)
- [Pi session continuation implementation in pi-worktrunk](https://github.com/mavam/pi-worktrunk/blob/main/worktrunk.ts)
- [Worktrunk `wt switch`](https://worktrunk.dev/switch/)
- [Worktrunk worktree status](https://worktrunk.dev/list/)
- [Git stash documentation](https://git-scm.com/docs/git-stash)
