# Agents: Archive Lifecycle Feature Specification

Status: deferred feature specification\
Depends on: `agents-design.md` MVP\
Working feature name: agent archive

## 1. Purpose

The MVP has two useful states for a managed agent:

- stopped but fully restorable;
- deleted with no retained managed artifacts.

This feature adds a middle state for completed work that should disappear from
the active fleet without immediately losing its Pi-session history:

> An archived agent retains only its Pi session and an immutable metadata
> snapshot. Its operational resources are removed.

Archive is a natural extension of the MVP's flat resource model and idempotent
resource reconciler. It is not required for initial implementation because the
MVP can safely delete agents and already journals resource-level progress.

## 2. Relationship to the MVP

Archive does not introduce a workspace object or another execution model.

The MVP reconciles deletion toward an empty retained-resource set. Archive
uses the same planner with this desired retained set:

```text
Pi session
archive record and immutable snapshot
```

It removes or closes, when present and confirmed:

- live Kitty tab;
- Kitty restoration definition;
- Worktrunk worktree, only after other Git resources are resolved;
- each owned local branch;
- each owned remote branch;
- each owned open PR, by closing it rather than deleting GitHub history;
- active agent registry record after the archive record is durable.

Merged and already-closed PR records remain on GitHub as historical records.
Associated branches and PRs are retained externally unless a disclosed plan
explicitly adopts them. Every branch and PR disposition is independent.

Archive can be implemented after the MVP if the MVP preserves these seams:

- typed flat resource references;
- resource-level delete actions and completion journal;
- Pi-session removal as an independent action;
- agent/resource reconciliation separate from selection policy;
- durable agent records separated from disposable observation caches;
- globally unique agent IDs.

The active observation cache is neither an archived artifact nor safety
evidence. Archive captures a fresh snapshot, retains the Pi session and archive
record, and removes the active cache with the active record.

## 3. Terminology

### 3.1 Archived agent

A former managed agent represented by an archive record and an archived Pi session.
It has no worktree, branch/PR ownership or association, restoration definition,
or live Kitty tab and is not restorable by the active-agent restore operation.

The UUID is preserved across active and archived records.

### 3.2 Archive snapshot

Immutable metadata captured immediately before operational teardown. It
describes the agent, repository, every branch/commit and PR state, delegation
ancestry, and the resource actions that produced the archive.

The snapshot records state; it does not preserve repository files, patches,
Git objects, build products, ignored files, or terminal state.

### 3.3 Archive cleanup

Permanent removal of an archived Pi session and its archive record. This is
the final garbage-collection operation and is plan/confirm/execute like active
agent deletion.

There is no background retention daemon. Archive cleanup occurs only when it is
explicitly requested through a running Pi process.

## 4. Goals

The feature must support:

1. Archiving one stopped, safe agent.
1. Planning and archiving several agents selected by deterministic policy.
1. Retaining the exact Pi session independently of the deleted worktree.
1. Capturing every branch and PR, their commit/merge state, delegation
   ancestry, and teardown outcomes.
1. Listing and inspecting archives separately from active agents.
1. Permanently deleting explicitly selected archives.
1. Cleaning archives older than a requested retention period.
1. Resuming archive or archive-cleanup operations after interruption.

## 5. Non-goals

This feature does not:

- restore or unarchive an agent into a new worktree;
- preserve a Git bundle, patch, untracked files, ignored files, or build state;
- make an archived Pi session safely executable against its former cwd;
- preserve Kitty tabs or generated restoration definitions;
- automatically close or delete resources that are merely associated without
  a disclosed ownership decision;
- run archive retention on a timer or daemon;
- compact, summarize, rewrite, index, or otherwise alter Pi-session contents;
- archive an agent while it is working or waiting;
- create a second nested archive/workspace domain model.

An unarchive/materialization workflow may be specified later, but is not
implied by retaining a Pi session.

## 6. Normative requirements

| ID    | Requirement                                                                                                                                   |
| ----- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| AR-01 | Archive shall retain exactly one byte-verified Pi session and one immutable archive record for each successfully archived agent.              |
| AR-02 | Archive shall remove every confirmed operational resource from the active agent's flat resource list.                                         |
| AR-03 | Archive shall require the agent to be stopped before the first destructive mutation.                                                          |
| AR-04 | Archive shall require a clean worktree and no in-progress Git operation.                                                                      |
| AR-05 | Automated archive policy shall require every commit uniquely reachable from any branch scheduled for deletion to be durably reachable from a retained ref. |
| AR-06 | Any explicit archive that discards unmerged or uniquely reachable commits from any branch shall identify each loss separately and require confirmation. |
| AR-07 | The archive snapshot and verified Pi-session copy shall be prepared before any worktree or branch removal.                                    |
| AR-08 | A Pi session stored within the worktree shall be copied into archive storage and verified before Worktrunk removal.                           |
| AR-09 | Each open PR shall be closed only when its own resource is owned or explicitly adopted on confirmation.                                       |
| AR-10 | Archive shall preserve merged and closed PR history and shall never claim to delete a GitHub PR.                                              |
| AR-11 | Every resource action shall be independently idempotent and journaled before the next action.                                                 |
| AR-12 | The active agent record shall remain until all teardown actions succeed and the archive record is durable.                                    |
| AR-13 | Archiving a parent shall never make children implicit candidates; each remaining child edge shall be resolved by independent archive/delete, reparenting, or detachment before the parent disappears. |
| AR-14 | Archive cleanup shall delete only the archived Pi session and archive record named in a confirmed, expiring plan.                             |
| AR-15 | Retention age shall be computed from `archivedAt`, not inferred from filesystem timestamps.                                                   |
| AR-16 | Archive and cleanup retries shall converge after interruption without repeating unsafe external effects.                                      |
| AR-17 | Unknown archive schemas shall be read-only and ineligible for cleanup.                                                                        |
| AR-18 | Archive metadata shall remove credentials and other secret material from stored remote URLs and operation diagnostics.                        |
| AR-19 | Archive planning and execution shall freshly observe every safety-relevant source and shall not rely on the active agent's observation cache. |
| AR-20 | Successful archive shall remove the active observation cache; the cache shall never be copied into archive storage.                           |
| AR-21 | Every branch and PR shall have an independently recorded ownership decision and terminal disposition before the one worktree is removed.       |
| AR-22 | Current branch shall be captured as observed state only and shall not be treated as archived agent identity.                                   |

## 7. Eligibility and safety

### 7.1 Normal archive eligibility

An agent is normally eligible when:

- exactly one registered agent record exists;
- no matching Kitty tab exists;
- the worktree exists and is clean;
- no merge, rebase, cherry-pick, revert, bisect, or conflict is in progress;
- the Pi-session file exists and is readable;
- worktree, current checkout, every branch, every PR, and restoration definition
  reconcile unambiguously;
- every commit reachable only from an owned branch scheduled for deletion is
  merged or otherwise reachable from a ref that will be retained;
- every child edge is resolved before the parent disappears: the child is
  independently selected, explicitly reparented, or explicitly detached;
- the agent is not provisioning, deleting, broken, current, or unknown schema.

A cached healthy, clean, or merged result is insufficient. Eligibility is
computed from fresh observations for the plan and repeated under execution
locks.

### 7.2 Abandoned unmerged work

The archive format intentionally does not retain source code. Therefore a
commit reachable only from a branch scheduled for deletion cannot be called
safe merely because its hash appears in metadata.

For each branch containing abandoned unmerged work, the planner must choose one
of these outcomes independently:

1. retain the local/remote branch externally and release its association from
   the archived agent rather than deleting it;
1. refuse until the user creates a durable Git ref or merges the work;
1. explicitly disclose the exact uniquely reachable commits that will be
   discarded and require a destructive override distinct from ordinary archive
   confirmation.

Automated policy archive may use only the first two outcomes. It never chooses
destructive discard.

### 7.3 PR and remote-branch behavior

The following table applies independently to every explicit PR resource; one
safe PR does not make another safe:

| State                         | Archive behavior                                                         |
| ----------------------------- | ------------------------------------------------------------------------ |
| PR merged                     | Preserve GitHub record; resolve its referenced branch independently      |
| PR closed, unmerged           | Preserve GitHub record; verify commit reachability before branch removal |
| PR open and owned             | Plan explicit PR close, then independent branch disposition              |
| PR open and merely associated | Retain, or require disclosed adopt-on-confirmation                        |
| No registered PR              | Apply commit-reachability and branch-ownership rules directly            |

A PR's head-branch reference supplies cleanup ordering only. It does not contain
that branch resource or transfer ownership.

## 8. Archive storage

```text
${XDG_STATE_HOME:-~/.local/state}/pi-agents/
  archives/
    <agent-uuid>/
      archive.json
      pi-session.jsonl
  operations/
    <operation-uuid>.json
  plans/
    <plan-token>.json
```

The implementation stages the Pi-session copy and archive JSON under
operation-private temporary names. It publishes them only after byte
verification and successful operational teardown.

Archive storage is user-readable only. The archive record stores a checksum of
the retained Pi session. It never stores arbitrary repository file contents.

## 9. Archive schema

```ts
type ArchivedAgentRecordV1 = {
  schemaVersion: 1;
  agentId: AgentId;
  name: string;
  parentAgentIdAtArchive: AgentId | null;
  childAgentIdsAtArchive: AgentId[];

  archivedAt: string;
  archiveReason: "explicit" | "policy";
  sourceAgentCreatedAt: string;

  repository: {
    commonDirAtArchive: string;
    primaryWorktreeAtArchive: string;
    githubNameWithOwner?: string;
    remotes: Array<{ name: string; url: string }>;
  };

  git: {
    currentBranchAtArchive: string;
    currentHead: string;
    defaultBranch: string;
    baseHead?: string;
    worktreeState: "clean";
    branches: Array<{
      scope: "local" | "remote";
      remote?: string;
      name: string;
      ownership: "owned" | "associated";
      tip: string;
      reachability: string[];
      disposition: "removed" | "retained" | "released";
    }>;
  };

  pullRequests: Array<{
    resource: Extract<AgentResourceRef, { kind: "pull-request" }>;
    status: PullRequestStatus;
    disposition: "closed" | "historical" | "retained" | "released";
  }>;
  observedAt: string;

  piSession: {
    archivedPath: string;
    originalPath: string;
    sha256: string;
    sizeBytes: number;
  };

  resourceSnapshot: AgentResourceRef[];
  teardown: Array<{
    resourceKind: AgentResourceRef["kind"];
    identity: string;
    action: string;
    outcome: "removed" | "closed" | "already-absent" | "retained";
    completedAt: string;
  }>;
};
```

The record is immutable after publication except for a future schema migration
that preserves the original snapshot. Archive-cleanup status belongs in an
operation journal, not by mutating historical fields.

Remote URLs in the snapshot are normalized display identities. Embedded
credentials, tokens, and credential-helper material are never copied into the
archive record.

## 10. Archive planning

Archive uses plan/confirm/execute:

```ts
type ArchivePlan = {
  token: string;
  createdAt: string;
  expiresAt: string;
  candidates: Array<{
    agentId: string;
    recordRevision: string;
    retained: ["pi-session", "archive-record"];
    resourceActions: ResourceAction[];
    warnings: string[];
    reason: string;
  }>;
  excluded: Array<{ agentId: string; reason: string }>;
};
```

The plan displays:

- the exact Pi session to retain;
- archive destination;
- observed current branch and HEAD without treating either as agent identity;
- every local/remote branch tip, ownership, disposition, and reachability;
- every PR state, ownership, head-branch reference, and close/retain action;
- commit-reachability evidence per branch;
- children independently selected or blocking, plus any required reparent or
  detach operation;
- any explicit irreversible code discard.

Execution accepts only the opaque plan token. It cannot introduce new agents,
paths, resource actions, or discard decisions.

Cached observations may populate the first screen while planning begins, but
the final plan is produced only from fresh adapter results. If a required
source cannot be observed, the candidate is excluded rather than accepted from
cache.

## 11. Archive execution

For each independently selected candidate, process a selected child before its
parent only when needed for relationship integrity:

1. acquire agent and repository locks;
1. revalidate the plan revision, stopped state, Git safety, delegation edges,
   every branch/PR state, ownership, and reachability;
1. create an archive operation journal and mark the active agent as archiving
   through operation state;
1. capture the immutable metadata snapshot;
1. copy the Pi session to an operation-private archive path;
1. verify size and SHA-256 against the source;
1. execute and journal every confirmed PR and branch action independently,
   retaining/releasing associated resources without external mutation;
1. only after all PRs and branches have terminal dispositions, remove the exact
   Worktrunk worktree; if Worktrunk couples the checked-out branch effect,
   verify and journal branch and worktree outcomes separately;
1. remove the restoration definition;
1. verify no live tab or operational resource remains except anything the plan
   explicitly retained externally and released from agent ownership;
1. atomically publish `pi-session.jsonl` and `archive.json`;
1. remove or trash the original Pi-session file when it is distinct from the
   published copy;
1. remove the disposable active observation cache;
1. remove the active agent record last;
1. complete and eventually discard the operation journal.

An active Pi session is never archived in place. The user stops it first so no
process can append to the JSONL during copying.

## 12. Idempotence and interruption

Archive is forward-only. The operation journal records at least:

```ts
type ArchiveOperation = {
  operationId: string;
  agentId: string;
  planToken: string;
  sourceRevision: string;
  phase:
    | "snapshot"
    | "pi-session-copied"
    | "resources-removing"
    | "archive-published"
    | "active-record-removing"
    | "completed"
    | "error";
  completedResourceActions: string[];
  sourcePiSessionSha256?: string;
  stagedArchivePath?: string;
  lastError?: string;
};
```

Retry rules:

- a verified staged Pi-session copy is reused;
- an already-closed or merged PR is success for that exact journaled PR;
- an already-absent local/remote branch is success when journaled by this
  operation;
- already-removed Worktrunk resources are success when exact prior worktree and
  any coupled branch identities are journaled;
- an already-published matching archive is reused after checksum and schema
  verification;
- active/archive record duplication is reconciled using the operation journal,
  never by deleting one heuristically.
- a missing active observation cache is success because it is disposable.

If the Pi-session checksum changes after the copy, refuse publication and keep
both copies for inspection. This normally indicates that a supposedly stopped
Pi process wrote to the source.

## 13. Listing and inspection

The model-callable `agents` tool adds these action variants:

```text
archive_plan
archive_execute
archive_list
archive_inspect
archive_delete_plan
archive_delete_execute
archive_cleanup_plan
archive_cleanup_execute
```

`/agents` may add an explicit **Archived** view. Archived agents never appear
as working, waiting, stopped, or restorable. Their display emphasizes:

- archive time and reason;
- repository, observed former checkout, and every branch disposition;
- current HEAD plus each branch tip/reachability;
- every PR number/state/merge time;
- Pi-session availability;
- planned retention or cleanup eligibility.

Archive list state comes from immutable archive records. It does not create or
retain live-agent observation caches for archived agents.

## 14. Archive cleanup

Archive cleanup reconciles the retained set toward empty:

1. select archive records by explicit IDs or `archivedOlderThanDays`;
1. reject unknown schema, active operation, missing/ambiguous identity, or a
   Pi-session file whose checksum no longer matches without explicit repair;
1. create an expiring plan naming exact archive IDs, paths, checksums, and
   reasons;
1. after confirmation, trash/unlink the archived Pi session;
1. remove the archive record and empty archive directory last;
1. journal each step so retries converge.

Age is calculated from `archivedAt` with the extension's clock. PR merge time
may be shown as context but is not the retention clock.

No GitHub, Git, Worktrunk, or Kitty mutation should remain at this stage. If it
does, the archive was incomplete and cleanup must refuse until reconciliation.

## 15. Delegation-ancestry behavior

Archive policy evaluates every agent independently. Parentage cannot add a
child to an archive plan or transfer any child resource action to the parent.
If parent and child independently qualify and are both confirmed, processing
the child first is only referential-integrity ordering, not cascading cleanup.

Before a parent leaves the active registry, the UI may offer a separate
confirmed relationship operation:

- reparent a child to the archived parent's `parentAgentId`;
- detach it as a top-level agent with `parentAgentId: null`; or
- independently archive/delete the child.

Manager code performs reparent/detach, updates affected `parentAgentId` links,
and rotates communication capabilities. Models cannot write raw parent agent
IDs. The relationship mutation is captured in the archive snapshot and is not
silently bundled into resource teardown.

Deleting an archive does not rewrite historical delegation IDs in other
archives; they are snapshot metadata, not live foreign keys.

## 16. Failure handling

- If snapshot or Pi-session copy fails, mutate no operational resource.
- If teardown fails, keep the active record, staged archive data, and operation
  journal; resume forward later.
- If publication fails after teardown, keep staged verified data and make the
  operation the highest-priority recovery item.
- If active-record removal fails after publication, show one interrupted
  archive, not two independent agents.
- Never respond to a failure by force-removing worktrees, resetting Git, or
  discarding a verified Pi-session copy.

## 17. Suggested implementation order

1. Generalize the MVP delete reconciler from “remove all” to an explicit
   retained-resource set.
1. Implement immutable archive snapshot construction as a pure function.
1. Implement Pi-session copy, checksum, staging, and atomic publication.
1. Add archive planning for stopped agents with merged PRs.
1. Add idempotent teardown and interrupted-operation recovery.
1. Add explicit single-agent archive UI.
1. Add archive list/inspect.
1. Add archive deletion and age-based archive cleanup.
1. Add open/closed-unmerged PR and explicit-discard policies last.

## 18. Acceptance criteria

1. Archiving a stopped merged agent resolves every local/remote branch and PR
   independently, removes its worktree last, and retains a checksum-verified Pi
   session and snapshot.
1. The archive snapshot records repository, observed current checkout, every
   branch tip/reachability, every PR and `mergedAt`, delegation ancestry, and
   each resource disposition.
1. A Pi session originally stored inside the worktree survives worktree
   removal byte-for-byte.
1. An active, dirty, conflicted, broken, or ambiguous agent is refused before
   mutation.
1. Automated archive refuses uniquely reachable unmerged code.
1. An open associated PR is never silently closed.
1. A crash after every execution step is resumable and retains the Pi session.
1. An archived agent is not offered by active restore.
1. Archive cleanup older than a chosen age deletes only the archived Pi session
   and archive record after confirmation.
1. A cleanup retry treats its own already-removed artifact as success but
   treats unexplained pre-existing absence as broken state.
1. Parent selection never cascades to children; independent selection plus
   explicit reparenting/detachment preserves live delegation integrity.
1. No feature path introduces a workspace aggregate or daemon.
1. A stale cache claiming clean/merged state cannot make an otherwise
   unobservable agent eligible for archive.
1. Successful archive removes the active cache and retains only the Pi session
   and immutable archive record.

## 19. Testing implications

Archive tests follow the shared
[testing strategy](agents-testing-strategy.md):

- snapshot construction, per-branch/PR eligibility, plan generation,
  delegation ordering without cascading selection, and operation transitions
  are pure Vitest tests;
- scripted fake adapters provide fresh Git, GitHub, Kitty, and Worktrunk
  observations and effect outcomes;
- a fault-injecting store simulates failure before and after every archive
  phase;
- real temporary directories are used only for Pi-session copy/checksum,
  atomic archive publication, and restart recovery;
- no automated test creates a real PR, controls Kitty, or removes a real
  Worktrunk worktree.

## 20. References

- [MVP design](agents-design.md)
- [Testing strategy](agents-testing-strategy.md)
- [Delegation and communication security](agents-delegation-communication.md)
- [Pi sessions](https://pi.dev/docs/latest/sessions)
- [Worktrunk `wt remove`](https://worktrunk.dev/remove/)
- [GitHub CLI](https://docs.github.com/en/github-cli)
