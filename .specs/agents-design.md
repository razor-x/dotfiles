# Agents: MVP Design Specification

Status: draft for local prototyping\
Audience: Razor X\
Implementation home: `razor-x/dotfiles`\
Extension name: `agents`\
Local extension path: `local/agents`

## 1. Document suite

This document defines the initial implementation. Three additive feature
specifications deliberately remain outside the MVP, and two companion documents
define shared implementation strategy:

- [Archive lifecycle](agents-archive.md): retain a Pi session and
  metadata snapshot while removing the agent's operational resources.
- [Dirty or non-default primary-worktree promotion](agents-transactional-promotion.md):
  transfer staged, unstaged, and untracked state, or move an existing feature
  branch out of the primary worktree.
- [Multi-repository control](agents-multi-repo-control.md): run Pi
  above several repositories and operate on their agents as one management
  scope.
- [Testing strategy](agents-testing-strategy.md): use Vitest, a
  functional core, fake adapters, narrow persistence contracts, and manual
  external-system acceptance checks.
- [Runtime dependency policy](agents-dependency-policy.md): use Pi-provided
  APIs and Node primitives while keeping the MVP free of additional runtime npm
  dependencies.

The MVP must expose the seams those features need, but must not implement their
user-facing behavior prematurely.

## 2. Summary

`agents` is a local Pi extension for creating, observing, stopping,
restoring, and deleting durable coding agents. It coordinates existing systems
rather than replacing them:

- Pi owns Pi sessions and agent execution.
- Worktrunk owns Git worktree creation, removal, and related hooks.
- Kitty owns live terminal tabs.
- GitHub, queried through `gh`, owns pull-request state.
- The extension records the stable agent identity that binds those resources.

The central invariant is:

> One active managed agent owns exactly one persisted Pi session, exactly one
> non-primary Worktrunk worktree and branch, and at most one Kitty tab while
> running.

A provisioning record is the durable, potentially incomplete path toward that
invariant and may initially own no resources.

An agent owns a flat list of independently identifiable resources. There is no
separate `Workspace` domain object. Stop, restore, delete, and later archive are
idempotent reconciliation operations over that resource list.

The repository's primary worktree is outside managed-agent ownership. A normal
Pi session there may inspect and manage the repository's agents. When its work
deserves isolation, the user can promote the current Pi session into a managed
agent in a new Worktrunk worktree.

The product surface is the Pi extension. There is no user-facing companion CLI,
daemon, external database, or standalone TUI.

## 3. Settled decisions

These are requirements, not open design questions:

1. **Extension-only interface.** Natural-language management uses narrow,
   model-callable Pi tools. `/agents` is the stable direct Pi command
   namespace: no arguments open the overview, while subcommands
   deep-link into focused interactive flows. Subcommand names are UX routing,
   not a second domain API. Shell programs remain implementation details.
1. **No daemon.** A currently running Pi process performs each operation and
   reconstructs current state on demand.
1. **Agents own flat resources.** A managed agent record contains resource
   references, not a nested workspace aggregate.
1. **The primary worktree is never owned.** It is not registered, restored,
   archived, or deleted as an agent resource.
1. **One Kitty tab is one running agent.** Arbitrary tab contents, panes,
   scrollback, editors, and process topology are not persisted.
1. **Restore is semantic.** It creates a new tab using user-managed Kitty
   configuration, changes to the agent worktree, and resumes the exact Pi session.
1. **Worktrunk remains authoritative.** The extension does not implement raw
   worktree lifecycle in parallel or bypass Worktrunk safety behavior.
1. **Agents may have child agents.** Each child independently owns its own Pi session,
   worktree/branch, and live tab.
1. **Unmanaged agents are not indexed.** “Unmanaged agent” is an informal
   description of work outside the registry, not a stored state or discovery
   requirement.
1. **Destructive selection is deterministic.** Extension code computes and
   validates candidates, presents exact resource actions, and executes only a
   confirmed immutable plan.
1. **Resource removal is idempotent and forward-only.** Interrupted deletion
   resumes remaining actions. It does not attempt a distributed rollback
   across Kitty, Git, GitHub, Pi, and the filesystem.
1. **MVP deletion removes the entire agent.** Archiving is a later operation
   that retains only the Pi session and archive metadata.
1. **MVP promotion is intentionally narrow.** The current Pi session must be
   persisted, in the primary worktree, clean, and on the default branch.
1. **MVP management scope is one repository.** The state layout is globally
   enumerable so directory-scoped multi-repository control can be added
   without migrating agent records.
1. **Durable identity is separate from observation.** The agent record stores
   identity, resource references, ownership, and lifecycle intent. A separate
   disposable cache stores the most recently observed external state.
1. **Reconciliation is observation-driven.** Commands observe current reality
   and derive status. Optional Worktrunk hooks may request a full refresh but
   never apply semantic event deltas directly to agent records.
1. **Development is acceptance-driven.** Each implementation increment ends
   in a runnable Pi behavior with inspectable state. The first increment of
   the creation flow exposed through `/agents` persists an empty
   `provisioning` record and performs no external resource mutation; later
   increments extend that same operation.
1. **The extension is named `agents`.** Its local source lives at
   `local/agents`, its persistent state root is `agents`, and its model-callable
   tool and direct Pi command namespace are both named `agents`.

## 4. Terminology

This document reserves bare **agent** for the extension-managed unit. The word
**session** is used only as part of a tool-owned term such as **Pi session** or
**Kitty session**; it is never a synonym for an agent.

### 4.1 Pi session

A session as defined and persisted by Pi, normally represented by a Pi JSONL
file. The extension preserves Pi's own term rather than renaming it
“conversation.”

Every active managed agent owns exactly one Pi session. A provisioning record
may not own one yet. Not every Pi session is a managed agent.

### 4.2 Agent and managed agent

An **agent** is a Pi-based unit of work. A **managed agent** is an agent
registered with this extension and bound to managed resources by a stable UUID.

Within the extension UI and this specification, bare “agent” means “managed
agent” unless explicitly qualified as unmanaged. `/agents` therefore lists
only managed agents.

The UUID—not the name, branch, path, tab title, PR number, or Pi filename—is the
agent's stable identity.

### 4.3 Unmanaged agent

An informal description of a Pi agent that is not registered with the
extension. It may have an ordinary persisted Pi session, but the extension
does not enumerate it, infer ownership of its resources, or assign it a
lifecycle state.

A current unmanaged Pi session may still invoke management tools. The special
promotion source needed by the MVP is described literally as **the current
primary-worktree Pi session**; it is not a separately named entity.

An actual `pi --no-session` process may manage existing agents but cannot be
promoted in the MVP because it has no persisted source Pi session.

### 4.4 Child agent

A managed agent whose record contains `parentId`. Parentage represents durable
ownership and organization, not shared filesystem or process state. Parent and
child own separate resources.

The MVP creates children only in the same repository. Cross-repository
parentage is specified by the multi-repository feature.

### 4.5 Controller role and management scope

“Controller” describes what the current Pi process is doing; it is not a
stored entity. In the MVP, operations default to the Git repository containing
the current working directory. A Pi session in the primary worktree is the
normal repository-wide controller, while a managed agent can manage itself and
its descendants.

Directory-derived scopes spanning several repositories are deferred.

### 4.6 Agent record and observation cache

The **agent record** is durable state describing what the agent is and what it
owns. The **observation cache** is disposable state describing what the
extension most recently saw when it inspected those resources.

The cache may be missing, corrupt, stale, or asynchronously refreshed without
changing agent identity. It is never authoritative for destructive safety
decisions.

### 4.7 Runtime and lifecycle terms

- **Working:** a live Pi process is processing a turn or executing tools.
- **Waiting:** a live Pi process is idle and awaiting input.
- **Stopped:** no live Kitty tab exists, but the durable resources needed to
  restore the agent remain.
- **Provisioning:** creation or promotion has begun but activation is not
  complete.
- **Broken:** observed resources disagree with the registered binding.
- **Deleting:** a confirmed resource-removal plan is being reconciled toward
  an empty resource set.

Working, waiting, and stopped are observations. Provisioning, deleting, and
error are persisted operation/lifecycle states.

### 4.8 Operations

- **Promote:** derive a managed Pi session from the current Pi session, create
  its Worktrunk resources, and continue in the same Kitty tab.
- **Spawn child:** create a fresh managed child agent in a new tab.
- **Stop:** close the live tab while retaining durable resources.
- **Restore:** recreate a tab and resume the exact Pi session.
- **Delete:** reconcile all confirmed owned resources toward absence, then
  remove the agent record.
- **Cleanup:** select agents by deterministic policy and execute deletion for
  the confirmed set.
- **Archive:** deferred operation that removes operational resources but
  retains the Pi session and an immutable snapshot.

## 5. MVP goals

The MVP must support:

1. Starting Pi normally in a repository and inspecting that repository's
   agents.
1. Promoting a clean, persisted Pi session from the default branch of the
   primary worktree without losing its history or changing tabs.
1. Spawning a child agent with its own branch, worktree, Pi session, and tab.
1. Seeing working, waiting, stopped, provisioning, and broken status.
1. Seeing agent activity in the Kitty tab title and Worktrunk marker.
1. Stopping an agent without deleting its durable resources.
1. Restoring one or more agents after Pi, Kitty, or the computer restarts.
1. Focusing a live agent's tab.
1. Inspecting GitHub PR, check, review, closed, and merged state on demand.
1. Deleting an explicitly selected agent through a resource-level plan.
1. Closing an owned open PR and removing owned branches as part of confirmed
   deletion.
1. Cleaning up agents whose PRs were merged more than a requested age ago.
1. Resuming an interrupted deletion without repeating unsafe effects.
1. Reporting stale, partial, or orphaned state without silently deleting data.

## 6. MVP non-goals

The MVP does not:

- manage changes made directly in the primary worktree;
- promote an actual `pi --no-session` process;
- transfer staged, unstaged, untracked, ignored, or conflicted state during
  promotion;
- move a feature branch currently checked out in the primary worktree;
- archive agents or garbage-collect archives;
- manage more than one repository in a single operation or directory scope;
- recursively discover arbitrary unmanaged Pi sessions or repositories;
- persist arbitrary Kitty processes, panes, scrollback, or tab contents;
- keep Pi processes alive through reboot;
- poll GitHub in the background;
- merge pull requests automatically;
- implement a task DAG, role system, autonomous team protocol, or arbitrary
  inter-agent message bus;
- return a child agent's final response into its parent Pi session
  automatically;
- replace Pi's `/resume` or build a historical transcript search system;
- provide a generic installation or support surface outside the dotfiles
  repository.

## 7. Normative requirements

“Must” and “shall” are normative.

### 7.1 Functional requirements

| ID    | Requirement                                                                                                                                                                                                                                                         |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| FR-01 | The extension shall load globally so a Pi process in any configured repository can manage that repository's agents without project-local installation.                                                                                                              |
| FR-02 | The extension shall never register a repository's primary worktree as an agent-owned resource.                                                                                                                                                                      |
| FR-03 | An active managed agent shall bind one stable UUID, one persisted Pi session, one non-primary Worktrunk worktree and local branch, and at most one live Kitty tab; a `provisioning` record may contain only the resources successfully created so far.              |
| FR-04 | Agent-owned and agent-associated artifacts shall be represented as a flat list of typed resource references.                                                                                                                                                        |
| FR-05 | The current Pi session shall be promotable when it is persisted, interactive, in the primary worktree, clean, and on the default branch.                                                                                                                            |
| FR-06 | Promotion shall derive a destination Pi session in the target cwd, retain the source Pi session, switch the current runtime, and continue in the same Kitty tab.                                                                                                    |
| FR-07 | A managed agent shall be able to spawn a managed child with independent resources and a durable `parentId`.                                                                                                                                                         |
| FR-08 | The extension shall expose typed model-callable operations and a direct `/agents` Pi command namespace; `/agents` with no arguments shall open the overview, while recognized subcommands shall deep-link into context-filtered interactive flows.                  |
| FR-09 | Status shall be derived from a complete observation snapshot of Worktrunk, Kitty, Pi-session existence, Git, and optionally GitHub; cached observations are display hints only.                                                                                     |
| FR-10 | Working/waiting state shall appear in the Kitty tab title and Worktrunk marker while an agent is live.                                                                                                                                                              |
| FR-11 | Stop shall remove the live Kitty tab while retaining the Pi session, worktree, branches, registry record, and restoration definition.                                                                                                                               |
| FR-12 | Restore shall recreate a tab from user-managed Kitty configuration and resume the exact registered Pi session.                                                                                                                                                      |
| FR-13 | Restore, focus, stop, and mutation operations shall use stable agent UUIDs after selection, never guessed titles or branch substrings.                                                                                                                              |
| FR-14 | GitHub state shall be queried through structured `gh` output and normalized independently of display text.                                                                                                                                                          |
| FR-15 | Delete and cleanup shall use plan/confirm/execute with an opaque expiring plan token.                                                                                                                                                                               |
| FR-16 | Every delete plan shall enumerate resource-level effects, including PR closure and local/remote branch removal when applicable.                                                                                                                                     |
| FR-17 | “Merged older than N days” shall use fresh GitHub `mergedAt` and an extension-computed cutoff.                                                                                                                                                                      |
| FR-18 | Deletion shall be resumable and idempotent after any completed resource action.                                                                                                                                                                                     |
| FR-19 | The agent record shall be removed only after all confirmed resources reach their desired absent state.                                                                                                                                                              |
| FR-20 | A parent agent shall not be deleted while a non-candidate managed descendant remains.                                                                                                                                                                               |
| FR-21 | Durable agent records shall contain identity, hierarchy, repository identity, resource references, ownership, lifecycle intent, revision, and timestamps but no authoritative observed status.                                                                      |
| FR-22 | Each agent may have a separate disposable observation-cache record tied to the current agent revision and resource fingerprint.                                                                                                                                     |
| FR-23 | Missing, malformed, unknown-schema, revision-mismatched, or fingerprint-mismatched observation caches shall be ignored and rebuilt by observation.                                                                                                                  |
| FR-24 | Every destructive plan and execute operation shall obtain fresh observations after acquiring its required locks and shall never rely on cached safety conclusions.                                                                                                  |
| FR-25 | Worktrunk hooks, if configured, shall only request full repository reconciliation; they shall not directly mutate agent resources or apply lifecycle deltas.                                                                                                        |
| FR-26 | The agent-creation flow shall atomically persist a revision-zero `provisioning` agent record with an empty resource list before its first external resource mutation, and creation shall be resumable from that durable intent.                                     |
| FR-27 | `/agents` subcommands shall be UI routes rather than mutation authority: each route shall derive eligible agents from the current scope, resolve selections to stable UUIDs, and invoke the same typed application operations used by the model-callable interface. |
| FR-28 | Batch-appropriate `/agents` flows shall be able to use interactive multi-selection and shall report independent per-agent outcomes; destructive flows shall still use their required plan/confirm/execute protocol.                                                 |

### 7.2 Safety requirements

| ID    | Requirement                                                                                                                                                                                     |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SR-01 | The extension shall never invoke Worktrunk or Git force-removal options.                                                                                                                        |
| SR-02 | Model-provided paths, titles, names, branch strings, or shell fragments shall never flow directly into destructive commands.                                                                    |
| SR-03 | Destructive operations shall revalidate topology, ownership, cleanliness, liveness, and plan freshness after acquiring locks.                                                                   |
| SR-04 | A dirty, live, current, primary, ambiguous, broken, unknown-schema, or unpushed agent shall be ineligible for automated cleanup.                                                                |
| SR-05 | A PR or remote branch that is merely discovered shall not be modified without the deletion plan explicitly disclosing and adopting that action.                                                 |
| SR-06 | A GitHub PR record shall never be described as deleted; an open PR may only be closed. Historical merged/closed PRs remain on GitHub.                                                           |
| SR-07 | Missing resources count as idempotent success only when a confirmed operation previously established the exact identity and intended removal. Pre-existing unexplained absence is broken state. |
| SR-08 | The current Pi process shall never delete the agent it is actively running as.                                                                                                                  |

### 7.3 Non-functional requirements

| ID     | Requirement                                                                                                                                                                                 |
| ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| NFR-01 | The implementation shall require no daemon, public CLI, external database, or installation layer.                                                                                           |
| NFR-02 | Registry and operation-record writes shall be atomic and safe under concurrent Pi processes.                                                                                                |
| NFR-03 | Kitty or `gh` failure shall degrade the relevant operation explicitly without corrupting other state.                                                                                       |
| NFR-04 | Adapters shall be independently fakeable for orchestration and destructive-policy tests.                                                                                                    |
| NFR-05 | Agent records shall include canonical repository identity so a later directory controller can filter them without schema migration.                                                         |
| NFR-06 | The domain core shall expose deterministic reconciliation, planning, and operation-transition functions independent of Pi UI, subprocesses, clocks, random IDs, and filesystem persistence. |
| NFR-07 | Observation-cache writes may be best-effort, but durable agent, plan, and operation-journal writes shall be atomic and revision-guarded.                                                    |

## 8. Ownership and sources of truth

| Concern                        | Authority                    | Extension responsibility                                        |
| ------------------------------ | ---------------------------- | --------------------------------------------------------------- |
| Pi session and model history   | Pi JSONL                     | Record the exact file and resume it                             |
| Worktree and local branch      | Git + Worktrunk              | Invoke Worktrunk, validate topology, never force                |
| Remote branch                  | Git remote                   | Record association/ownership and delete only when planned       |
| Live terminal topology         | Kitty                        | Discover, tag, create, focus, title, and close tabs             |
| Pull request                   | GitHub                       | Query through `gh`; close only through a confirmed owned action |
| Managed identity and hierarchy | Agent registry               | Persist UUID binding and parent relationship                    |
| Working/waiting signal         | Pi lifecycle events          | Report to Kitty and Worktrunk; cache the latest observation     |
| Last observed external state   | Disposable observation cache | Render quickly, track freshness/errors, and rebuild at any time |

The registry binds unrelated identifiers; it does not replace any underlying
authority.

### 8.1 Flat resource model

Repository identity and agent metadata are not resources. Everything the agent
may create, retain, close, or remove is represented as an independent resource
reference:

```ts
type AgentResourceRef =
  | {
      kind: "pi-session";
      path: string;
      ownership: "owned";
    }
  | {
      kind: "worktree";
      path: string;
      branch: string;
      ownership: "owned";
    }
  | {
      kind: "local-branch";
      name: string;
      ownership: "owned";
    }
  | {
      kind: "remote-branch";
      remote: string;
      name: string;
      ownership: "owned" | "associated";
    }
  | {
      kind: "pull-request";
      nameWithOwner: string;
      number: number;
      headRefName: string;
      ownership: "owned" | "associated";
    }
  | {
      kind: "kitty-tab";
      agentId: string;
      ownership: "owned";
      volatile: true;
    }
  | {
      kind: "kitty-restore-definition";
      path: string;
      ownership: "owned";
    };
```

The list is flat even when one action has dependencies on another. Dependency
ordering belongs to the reconciliation plan, not to a nested ownership model.

`associated` means the extension can prove a relationship but has not yet been
authorized to mutate the resource. A confirmed plan may explicitly adopt an
associated PR or remote branch for that operation. Merely seeing a matching
branch name is insufficient for silent mutation.

Kitty tab IDs are never persisted. The logical tab resource is discovered by
the agent UUID stored as a Kitty user variable.

## 9. Architecture

The same global extension loads into each Pi process:

```text
Current Pi process
  lifecycle reporter for itself, when managed
  model-callable agent-management tool
  /agents command and list UI
  orchestration service
    registry and operation journal
    observer, observation cache, and reconciler
    resource planner and operation reducer
    Pi session adapter
    Worktrunk adapter
    Kitty adapter
    Git/GitHub adapter
```

There is no resident controller. Durable agent records can be listed
immediately with their last cached observations. Runtime truth is reconstructed
whenever a management operation or `/agents` refresh observes the external
systems.

The architectural boundary is a functional core inside an imperative shell:

```ts
reconcile(agentRecord, observedSnapshot): DerivedAgentState
plan(command, agentRecord, derivedState): Decision
advance(operationState, effectResult): OperationTransition
```

Adapters obtain observations and execute planned effects. The core determines
derived state, refusals, resource actions, and resumable operation progress.

The resource planner accepts a current resource set and a desired retained set.
The MVP uses it for:

- stop: remove only the live Kitty-tab resource;
- restore: ensure the logical Kitty-tab resource exists;
- delete: retain no resources.

The archive feature will reuse the same mechanism with a retained set
containing the Pi session and archive record.

### 9.1 Prior-art boundary

- [`pi-worktrunk`](https://github.com/mavam/pi-worktrunk) is the implementation
  base because it already treats Worktrunk as authoritative and demonstrates
  safe Pi-session continuation into another cwd.
- [`pi-side-agents`](https://github.com/pasky/pi-side-agents) is a reference for
  child lifecycle, presentation, and recovery; its tmux and local-merge model
  is not adopted.
- [`@tintinweb/pi-subagents`](https://github.com/tintinweb/pi-subagents) is a
  reference for hierarchy UI; its background-process agents are a different
  execution model.
- [`Pi Session Manager`](https://github.com/Dwsy/pi-session-manager) may be
  useful later for historical Pi-session browsing, but is not the lifecycle
  base.

Copy only compatible, narrowly useful MIT-licensed code and preserve required
attribution.

## 10. Runtime storage and concurrency

Runtime state is local state and must not be committed to the dotfiles
repository.

```text
${XDG_STATE_HOME:-~/.local/state}/pi-agents/
  agents/
    <agent-uuid>.json
  observations/
    <agent-uuid>.json
  operations/
    <operation-uuid>.json
  plans/
    <plan-token>.json
  kitty/
    <agent-uuid>.kitty-session
```

The registry is per-user and globally enumerable even though the MVP filters
operations to one repository. One file per agent avoids a global
read-modify-write race and prepares for multi-repository directory scope.
Observation caches are stored separately so cache loss or corruption cannot
damage durable ownership state.

Every write uses a restrictive temporary sibling, flush/close, and atomic
rename. Provisioning and destructive transitions acquire:

- an agent lock for agent-local mutation;
- a repository lock for worktree or branch-topology mutation;
- no process-global lock for ordinary lifecycle signals.

Agent, plan, and operation-journal writes use expected revisions where a stale
writer could otherwise overwrite newer durable state. Observation-cache writes
merge only source observations newer than the cached source timestamp. Losing
a cache race may make the UI temporarily stale but cannot alter ownership or
authorize an operation.

## 11. Agent record

```ts
type ManagedAgentRecordV1 = {
  schemaVersion: 1;
  id: string;
  revision: number;
  name: string;
  parentId: string | null;

  repository: {
    commonDir: string;
    primaryWorktree: string;
    githubNameWithOwner?: string;
  };

  resources: AgentResourceRef[];

  lifecycle: "provisioning" | "active" | "deleting" | "error";
  createdAt: string;
  updatedAt: string;
};
```

Rules:

- Stored paths are absolute and canonical.
- `repository.commonDir` identifies a Git repository across all its worktrees.
- The primary-worktree path is stored for scoping and safety, never as an owned
  resource.
- Resource-kind cardinalities enforce the central invariant once lifecycle is
  `active`.
- A `provisioning` record may initially have `resources: []`. It represents
  durable creation intent before the first external effect, not an active
  agent with missing resources.
- During provisioning, resources are appended only after their corresponding
  effects are verified. A fresh child may therefore temporarily lack its
  `pi-session` resource and adds it immediately after Pi creates the session.
- PR identity and ownership belong in `resources`; changing PR status belongs
  in the observation cache.
- Unknown schema versions are read-only.

### 11.1 Observation cache

```ts
type SourceObservation<T> = {
  observedAt: string;
  value?: T;
  error?: {
    code: string;
    message: string;
  };
};

type AgentObservationCacheV1 = {
  schemaVersion: 1;
  agentId: string;
  agentRevision: number;
  resourceFingerprint: string;
  updatedAt: string;

  sources: {
    pi?: SourceObservation<{
      sessionFileExists: boolean;
      activity: "starting" | "working" | "waiting" | "unknown";
    }>;
    worktrunk?: SourceObservation<{
      worktreeExists: boolean;
      branch: string | null;
      isPrimary: boolean;
    }>;
    git?: SourceObservation<{
      clean: boolean;
      head: string | null;
      unpushedCommits: boolean | null;
    }>;
    kitty?: SourceObservation<{
      matchingTabs: number;
    }>;
    github?: SourceObservation<PullRequestStatus | null>;
  };

  derived: {
    activity: "working" | "waiting" | "stopped" | "unknown";
    health: "healthy" | "broken" | "unknown";
    summary: string;
  };
};
```

The resource fingerprint is a stable hash of the record fields that determine
observation meaning: repository identity and resource references. A cache whose
agent revision or fingerprint does not match is ignored rather than migrated.

Source observations merge independently by `observedAt`; a newer Kitty result
does not make an older GitHub result fresh. `derived` is a convenience for
immediate display and is always recomputable.

Unknown cache schemas, malformed JSON, and missing cache files are equivalent
to an empty cache. They never make the durable agent record unreadable.

### 11.2 Identity inside Pi and Kitty

When an agent activates, append a custom Pi-session entry containing:

```json
{
  "managedAgentId": "<uuid>",
  "repositoryCommonDir": "...",
  "branch": "...",
  "worktreePath": "..."
}
```

Freshly launched Pi receives `PI_MANAGED_AGENT_ID`. The active Kitty tab gets:

```text
pi_managed_agent=<uuid>
```

Identity resolution order is:

1. custom managed-agent entry in the active Pi session;
1. `PI_MANAGED_AGENT_ID` supplied at launch;
1. exact registry match on the Pi-session file;
1. no managed identity.

These are recovery aids. The registry remains the canonical binding.

## 12. Observation and reconciliation

Listing uses a cache-first refresh sequence:

1. Load matching durable agent records and valid observation caches.
1. Render immediately from the cached derived state, marking missing or stale
   sources as unknown/stale.
1. Observe external systems and reconcile complete current snapshots.
1. Merge newer source observations into each cache.
1. Update the UI when the current Pi UI surface supports live refresh.

The MVP need not run a daemon. Observation occurs when `/agents`, a management
tool, a lifecycle event, or an operation provides a natural refresh
opportunity. A future background refresher can call the same observer and cache
merge functions without changing domain semantics.

Full repository observation performs:

1. Load matching agent records and capture their revisions/fingerprints.
1. Invoke `wt list --format=json` once for the repository.
1. Invoke `kitten @ ls` once and index tabs by `pi_managed_agent`.
1. Check each registered Pi-session and restoration-definition path.
1. Inspect local and remote branch topology when relevant.
1. Query GitHub only when requested or required by policy.
1. Construct an `ObservedAgentSnapshot` for each agent.
1. Derive status without silently repairing durable state or deleting anything.

| Record | Worktree | Pi session | Kitty tab | Derived result               |
| ------ | -------- | ---------- | --------- | ---------------------------- |
| yes    | yes      | yes        | one       | `working` or `waiting`       |
| yes    | yes      | yes        | none      | `stopped`, restorable        |
| yes    | no       | yes        | none      | `broken: worktree missing`   |
| yes    | yes      | no         | none      | `broken: Pi session missing` |
| yes    | no       | no         | none      | `broken: resources missing`  |
| yes    | yes      | yes        | multiple  | `broken: duplicate tabs`     |

A stale activity marker never proves liveness. With no matching Kitty tab, the
agent is stopped regardless of its last Pi event.

Reconciliation reports orphan resources only when their managed-agent UUID can
be proven. It never adopts or deletes them automatically.

Cached observations never satisfy a destructive precondition. Delete,
cleanup, archive, and promotion planning obtain fresh required observations;
execution repeats them after acquiring the relevant locks. If a source cannot
be freshly observed, the affected destructive action refuses rather than using
the last cached success.

### 12.1 Refresh triggers and Worktrunk hooks

Worktrunk hooks are optional refresh opportunities, not a semantic event
stream. A configured hook may request `refreshRepository()` after something
may have changed. It does not write “worktree created,” “branch removed,” or any
other partial transition into the agent record.

Extension-initiated Worktrunk operations always reconcile after `wt` returns,
so they require no hook for correctness. Manual Worktrunk activity becomes
visible on the next ordinary observation even if no hook runs.

Duplicate or concurrent refresh requests are safe because reconciliation reads
current reality. Refreshes for the same repository may be coalesced or
serialized, and an older source observation cannot replace a newer cached
source observation.

## 13. Pi integration

### 13.1 Lifecycle reporting

On Pi `session_start`, the extension resolves managed identity. If managed, it:

- validates cwd, Pi-session path, repository, and registered worktree;
- publishes a starting/waiting Pi source observation to the disposable cache;
- tags and titles the Kitty tab;
- updates the Worktrunk marker.

`agent_start`, `agent_end`, and `session_shutdown` update the Pi/Kitty cache
observations, Kitty title, and Worktrunk marker. They do not rewrite resource
ownership. Status-reporting or cache-write failures are warnings and must not
interrupt agent work.

### 13.2 Pi-session continuation

Clean promotion uses the proven `pi-worktrunk` approach:

1. wait for the current agent turn to be idle;
1. ensure the current Pi session is persisted;
1. call `SessionManager.forkFrom(sourceSession, targetCwd, targetSessionDir)`;
1. call `ctx.switchSession(destinationSession, ...)`;
1. append a visible transition note that earlier paths refer to the primary
   worktree;
1. retain the source Pi session as an unmanaged historical session.

This switch is performed only from a Pi context that cannot deadlock the agent
event loop.

### 13.3 Child startup

A fresh child tab starts ordinary interactive Pi with an initial prompt:

```text
PI_MANAGED_AGENT_ID=<uuid> pi --name <name> <initial-prompt>
```

The child extension obtains the Pi-session path, appends it to the resource
list, and changes the agent from `provisioning` to `active`. If registration
does not complete before a short timeout, retain all created resources and show
an error; the user may be at a trust, authentication, or login prompt.

## 14. Worktrunk integration

```ts
interface WorktrunkAdapter {
  list(repoCwd: string): Promise<Worktree[]>;
  create(branch: string, base: string, repoCwd: string): Promise<Worktree>;
  resolve(branchOrPath: string, repoCwd: string): Promise<Worktree>;
  remove(worktreePath: string, repoCwd: string): Promise<RemovalOutcome>;
  setMarker(worktreeCwd: string, marker: string | null): Promise<void>;
}
```

Rules:

- pin and validate Worktrunk's structured-output schema;
- use `--no-cd` because Pi controls runtime/Pi-session continuation;
- never expose force or auto-confirm flags through the adapter;
- never remove a primary or current worktree;
- preserve Worktrunk hook approval and failure behavior;
- remove by exact reconciled worktree path;
- treat retained local branches as unfinished resource actions, not success.

Extension-specific Worktrunk hooks, if added, request complete observation
and reconciliation only. They do not directly patch an agent record. Hooks
owned by the repository may continue performing their normal setup or cleanup
work as part of the Worktrunk command.

Ignored-file copying, dependency installation, dev servers, and project setup
remain Worktrunk hook/configuration concerns.

## 15. Kitty integration

### 15.1 Status and identity

The current managed tab is tagged with `pi_managed_agent=<uuid>`. Discovery
uses `kitten @ ls`; numeric window or tab IDs are not persisted.

Suggested titles:

```text
🤖 <name>   working
💬 <name>   waiting
… <name>    starting/restoring
! <name>    error
```

Worktrunk markers follow the same Pi lifecycle events. PR state need not appear
in the tab title for MVP.

### 15.2 Same-tab promotion

Promotion does not open another tab. After the Pi-session switch succeeds, the
extension tags the current tab, sets its title, and starts lifecycle reporting.

### 15.3 Restoration definition

The extension renders a user-owned Kitty template into a per-agent file. The
template receives:

```text
agent_id
agent_name
tab_title
worktree_path
pi_session_file
parent_id
```

Conceptually:

```text
new_tab {{tab_title}}
cd {{worktree_path}}
launch --var pi_managed_agent={{agent_id}} \
  env PI_MANAGED_AGENT_ID={{agent_id}} \
  pi --session {{pi_session_file}}
```

All values are escaped for Kitty session syntax and are never interpolated
through `sh -c`. A direct `kitten @ launch --type=tab` spike is acceptable
behind the same adapter, but the stable contract is a user-managed restoration
recipe rather than terminal resurrection.

Fresh-child startup may use a separate template because its Pi-session path is
unknown until Pi starts. Once registered, the durable restoration definition
is rendered with the exact Pi-session path.

## 16. GitHub integration

The GitHub adapter runs `gh` in the agent worktree and normalizes:

```text
none
draft
checks-running
checks-failed
review-needed
changes-requested
ready
merged
closed
unknown
```

```ts
type PullRequestStatus = {
  number: number;
  url: string;
  state: "OPEN" | "CLOSED" | "MERGED";
  isDraft: boolean;
  headRefName: string;
  headRepositoryOwner?: string;
  mergedAt: string | null;
  reviewDecision: string | null;
  mergeStateStatus: string | null;
  checks: "none" | "pending" | "passing" | "failing";
  observedAt: string;
};
```

Short in-memory caching is allowed for display. Authentication failure,
network failure, absent `gh`, or a non-GitHub remote becomes `unknown` and does
not corrupt local management.

For age policies, the model supplies a duration such as
`mergedOlderThanDays: 7`; extension code computes the timestamp cutoff.

## 17. User-facing Pi API

### 17.1 Model-callable tool

Begin with one action-discriminated tool named `agents`:

```text
list
inspect
promote
spawn_child
restore
focus
stop
delete_plan
delete_execute
cleanup_plan
cleanup_execute
```

Mutation actions accept agent UUIDs after selection. Names and branches are
search keys only; ambiguity returns candidates rather than guessing.

Tool guidance shall require:

- current-repository scope in the MVP;
- explicit freshness metadata whenever list/inspect returns cached observations;
- plan actions before destructive execute actions;
- adapter evidence before claiming success;
- no shell-command fallback after a managed operation refuses.

### 17.2 `/agents` direct command surface

`/agents` is a direct way to enter the agent-management UX without first
describing the desired operation to the model. It is not a textual mirror of
the `agents` tool schema and its subcommand vocabulary is not a domain
contract.

- `/agents` with no arguments opens the repository-scoped overview and action
  UI.
- A recognized subcommand deep-links into one focused flow, performs scope and
  eligibility filtering, and normally opens a picker rather than guessing a
  target from free-form text.
- A batch-appropriate flow may return several UUIDs from a multi-select picker;
  the application service then reports one outcome per agent.
- Canceling or selecting no agents has no effects.
- Unknown subcommands show concise help and perform no operation.

For example, a possible `/agents resume` route would show only stopped,
restorable agents, allow multi-selection, and invoke the existing restore
operation sequentially by UUID. Exact names—including `resume` versus
`restore` and the label for entering creation—remain UX choices until
prototyping makes the best vocabulary clear.

The creation flow available from the namespace ultimately runs clean promotion
through activation when invoked from a clean/default primary worktree. During
incremental development, it is deliberately implemented phase by phase. It
must report the truthful `provisioning` result reached by the current
implementation and must never imply that an agent is active before its
required resources exist.

The list UI:

1. resolves the current repository;
1. loads durable records and valid observation caches immediately;
1. groups agents by parent/child relationship and renders cached status with
   per-source freshness;
1. starts or requests a full repository refresh;
1. updates affected rows when the selected Pi UI implementation supports it;
1. supports inspect, focus, restore, stop, and delete-plan;
1. shows explicit errors when cwd is not within one repository.

A custom fleet view is optional. An initial `ctx.ui.select` implementation may
render the cache and provide an explicit refresh/reopen action; live row updates
can arrive with the richer component. The cache/observer boundary must not
depend on either UI implementation.

Optional footer:

```text
agents 4 | 2 working | 1 waiting | 1 stopped
```

Do not poll GitHub to keep it updated.

## 18. Core operations

### 18.1 Clean promotion

Purpose: promote the current Pi session from the primary worktree into a new
managed agent while staying in the same Kitty tab.

Natural-language requests, the overview UI, and any eventual creation
subcommand delegate to the same operation.

Preconditions:

- interactive Pi with a persisted session file;
- cwd resolves to the repository's primary worktree;
- the primary worktree is on Worktrunk's default branch;
- no staged, unstaged, untracked, conflicted, or in-progress Git state;
- requested branch does not exist and has no worktree;
- current Kitty instance is remotely controllable;
- no concurrent repository mutation operation.

Sequence:

1. Wait for Pi to become idle.
1. Acquire the repository lock and repeat all preconditions.
1. Create an agent UUID and atomically write the revision-zero provisioning
   agent record with `resources: []`.
1. Create a provisioning operation record referring to that agent.
1. Create the requested Worktrunk branch/worktree from the recorded HEAD.
1. Verify the result, then append the worktree and local-branch resource
   references under an expected-revision write.
1. Derive the destination Pi session in the target cwd, verify its identity,
   and append its resource reference.
1. Switch the current Pi runtime to the destination Pi session.
1. Append identity and transition metadata.
1. Adopt the current Kitty tab, create/verify its restoration definition,
   update the Worktrunk marker, and append the verified logical resources.
1. Mark the agent active, invalidate any provisioning-era observation cache,
   and observe the activated agent.
1. Complete the operation record.

If failure occurs before the Pi switch, the source Pi session remains active.
Automatic rollback is allowed only when the operation can prove that the new
worktree/branch is unchanged and exclusively created by it. Otherwise preserve
the resources and an exact recovery record.

The refusal for advanced cases points to the separate promotion feature.

### 18.2 Spawn child

Inputs:

- name;
- new branch;
- initial prompt;
- optional parent agent ID;
- optional base, defaulting to the caller's current HEAD.

The MVP requires parent and child to share a repository.

Sequence:

1. Validate repository, base, branch absence, and optional parent.
1. Create UUID, persist an empty provisioning record, and create its operation
   record.
1. Create and verify the Worktrunk worktree, then append the worktree and
   local-branch resource references.
1. Render and verify the restoration definition, then append its resource
   reference.
1. Launch the configured fresh-child Kitty tab with UUID, cwd, name, and
   initial prompt.
1. Verify the tagged tab, append its logical resource, and leave the parent tab
   focused unless configured otherwise.
1. Let the child register its Pi-session resource and finalize activation.
1. Invalidate the provisioning cache when the durable resource revision changes
   and observe the active child.

No conversational result routing is implied by parentage.

### 18.3 Restore

Restore is an idempotent ensure-present operation for the logical Kitty tab:

1. Reconcile the agent.
1. Refuse if worktree or Pi session is missing.
1. If exactly one matching tab exists, focus it and report already running.
1. Refuse duplicate matching tabs.
1. Render the restoration definition from user configuration.
1. Load it into the current Kitty instance.
1. Wait briefly for identity/status, without interpreting an interactive login
   or trust prompt as destructive failure.

Batch restore is sequential initially to avoid duplicate races and expose
individual failures.

### 18.4 Stop

Stop is idempotent removal of the logical live-tab resource:

1. Discover by managed UUID.
1. If absent, report already stopped.
1. Refuse duplicate matches.
1. Request graceful Pi shutdown when practical, then close the tab.
1. Confirm absence, clear the Worktrunk marker, and merge a stopped Kitty/Pi
   observation into the cache.

It does not kill arbitrary processes in the worktree. Worktrunk tethering owns
processes intentionally coupled to worktree lifetime.

### 18.5 Focus

Focus resolves a live tab by UUID. If stopped, it offers restore rather than
silently starting the agent. It never matches by mutable title alone.

### 18.6 Delete planning

Deletion is resource reconciliation toward the empty set:

```text
request -> deterministic plan -> confirmation -> execute opaque token
```

```ts
type ResourceAction = {
  agentId: string;
  resource: AgentResourceRef;
  action:
    | "close-pr"
    | "delete-remote-branch"
    | "remove-worktree"
    | "delete-local-branch"
    | "close-kitty-tab"
    | "delete-kitty-restore-definition"
    | "trash-pi-session";
  ownershipDecision: "already-owned" | "adopt-on-confirmation";
  reason: string;
};

type DeletePlan = {
  token: string;
  createdAt: string;
  expiresAt: string;
  repositoryCommonDir: string;
  candidates: Array<{
    id: string;
    recordRevision: string;
    reason: string;
    actions: ResourceAction[];
  }>;
  excluded: Array<{ id: string; reason: string }>;
};
```

The plan must state that an open PR will be **closed**, not deleted. Merged and
already-closed PR records are preserved as GitHub history and require no
mutation.

Execute accepts only the token; it cannot add agent IDs, paths, or actions.
After locks, it revalidates record revisions, topology, liveness, cleanliness,
unpushed commits, descendants, GitHub state, and every adopted ownership
decision.

### 18.7 Idempotent delete execution

Per agent, execution uses dependency ordering but retains a flat resource
model:

1. mark the agent `deleting` and create an operation journal;
1. close the live tab if the explicit plan allows deleting a previously live
   agent; automated cleanup otherwise requires it already stopped;
1. close each confirmed, still-open PR;
1. remove each confirmed remote branch;
1. remove the worktree and local branch through Worktrunk;
1. remove the generated Kitty restoration definition;
1. move the Pi-session file to trash when available, otherwise unlink only
   under the confirmed plan;
1. remove the disposable observation cache;
1. verify every planned resource reached its absent/closed terminal state;
1. remove the agent record last.

After each action, persist completion in the operation journal. A retry does
not repeat completed effects:

- missing tab: success;
- PR already closed or merged: success;
- remote branch already absent: success;
- Worktrunk worktree/local branch already absent: success only when the
  operation journal proves they existed or were already removed by this plan;
- observation cache already absent: success;
- Pi session already trashed by this plan: success.

If an action fails, retain the agent record, all remaining resources, the
operation journal, and the exact next action. There is no cross-system rollback.

### 18.8 Policy cleanup

“Delete agents with PRs merged more than N days ago” is selection followed by
ordinary per-agent deletion.

Eligibility requires:

- fresh GitHub state is `MERGED`;
- `mergedAt` precedes the extension-computed cutoff;
- no live tab;
- worktree is clean;
- no unpushed commits or unique untracked data;
- required resource identities are unambiguous;
- no non-candidate descendant remains;
- agent is not current, primary, provisioning, deleting, broken, or unknown
  schema.

Descendants execute before parents. Failure of one agent is reported
independently and does not make successful deletions appear rolled back.

## 19. Safety invariants

1. The primary worktree can never appear in an agent's resource list.
1. Destructive adapters accept resolved resources, never arbitrary model paths.
1. Worktrunk/Git force options are absent from adapter interfaces.
1. Automated cleanup cannot delete a live, dirty, unpushed, ambiguous, broken,
   or current agent.
1. A plan is immutable, expiring, and revalidated under locks.
1. Registry removal follows external resource convergence.
1. Unknown schemas are never mutated.
1. Commands use argument arrays, not interpolated shell strings.
1. Names, branches, PR titles, model output, and repository content are
   untrusted display data.
1. Failure never falls back to `rm -rf`, `git branch -D`, `git reset --hard`,
   or an improvised shell cleanup.
1. A discovered PR/remote branch must be explicitly present in the confirmed
   action plan before mutation.
1. “Already absent” is safe only in a known idempotent retry context.

## 20. Failure handling and recovery

### 20.1 Principles

- preserve user data over tidy topology;
- journal before each irreversible or externally visible mutation;
- make every operation idempotent or interruption-detectable;
- report retained resources and the exact incomplete action;
- repair only through explicit user selection.

### 20.2 Interrupted operations

Provisioning and deletion records contain operation ID, agent ID, repository,
phase, resource actions, completed actions, and last error.

The next management request surfaces interrupted work before the normal list:

```text
Interrupted deletion: api-cache
  PR closed
  remote branch removed
  worktree still present
  Pi session retained

Resume deletion or inspect resources?
```

Rollback is offered only for newly provisioned, provably untouched resources.
Deletion always resumes forward.

## 21. Configuration and source layout

Configuration remains a local TypeScript object:

```ts
export const agentsConfig = {
  stateRoot: "~/.local/state/pi-agents",
  kitty: {
    templatePath: "<dotfiles>/kitty/sessions/agent.kitty-session.template",
    managedVar: "pi_managed_agent",
    focusNewChildren: false,
  },
  github: { cacheMs: 45_000 },
  observations: {
    localStaleAfterMs: 10_000,
    githubStaleAfterMs: 60_000,
  },
  planTtlMs: 5 * 60_000,
  childStartupTimeoutMs: 15_000,
};
```

Suggested layout:

```text
<pi-extension-root>/local/agents/
  index.ts
  config.ts
  domain.ts
  registry.ts
  state-store.ts
  observation-cache.ts
  observe.ts
  reconcile.ts
  resource-planner.ts
  tools.ts
  commands.ts
  operations/
    promote.ts
    spawn.ts
    restore.ts
    stop.ts
    delete.ts
    cleanup.ts
  adapters/
    pi-session.ts
    worktrunk.ts
    kitty.ts
    git.ts
    github.ts
  ui/
    format.ts
    agent-picker.ts
  tests/

<kitty-config>/sessions/
  agent.kitty-session.template
```

The extension should adapt the narrow pieces of `mavam/pi-worktrunk` it needs
and subsume overlapping commands/markers rather than load both implementations
simultaneously.

## 22. Extension seams

The MVP includes only these seams for deferred features:

### 22.1 Archive seam

- Resource removal is expressed as convergence to a desired retained set.
- Pi-session removal is an independent final action.
- Operation journals can retain resource-level completion.

The MVP does not expose archived state, archive commands, archive storage, or
archive cleanup.

### 22.2 Advanced-promotion seam

- Worktree preparation is behind a `PromotionStrategy` boundary.
- Activation begins only after a strategy returns a verified target.
- Operation records can carry strategy-specific recovery metadata.

The MVP implements only clean/default-branch preparation.

### 22.3 Multi-repository seam

- The registry is globally enumerable.
- Every record contains canonical Git common-dir and primary-worktree identity.
- Reconciliation accepts an explicit record/repository selection internally.

The MVP UI and tool schema still reject directory and multi-repository scopes.

### 22.4 Asynchronous-observation seam

- Durable agent records and disposable observation caches use separate stores.
- Observer output is a complete source snapshot, not a semantic hook delta.
- Cache merging rejects older source observations and mismatched agent
  revisions/fingerprints.
- UI rendering can occur before refresh completes.

The MVP performs observation opportunistically in the current Pi process. It
does not require a daemon, persistent watcher, or asynchronous hook processor.

## 23. Incremental delivery plan

Development is organized as a sequence of independently assignable, runnable
increments. Each increment must state:

- the exact Pi interaction now available;
- the durable JSON and visible UI result;
- the external effects that may occur;
- the external effects that must not occur yet;
- the focused automated tests and short manual demonstration that prove it.

An integration spike may happen inside an increment when an API is uncertain,
but a spike is not itself the deliverable. Each deliverable ends in behavior
that can be launched and inspected from Pi. The implementation may start with
fewer files than the suggested source layout; it must preserve the domain,
operation, adapter, store, and UI boundaries rather than a particular file
count.

At intermediate stages, the creation action exposed through `/agents` advances
through every creation phase implemented so far, persists the truthful
`provisioning` state, and reports that later phases are not implemented. It
never fabricates successful external effects. The final MVP extends the same
application operation through activation rather than replacing a throwaway
prototype path.

### Increment 1: persist creation intent

**User-visible delivery:** launch Pi in a repository's primary worktree, run
`/agents`, choose the initially available creation action, and receive the new
agent UUID and state-file path.

The command atomically writes a `ManagedAgentRecordV1` containing repository
identity, `revision: 0`, `lifecycle: "provisioning"`, timestamps,
`parentId: null`, and `resources: []`.

This increment may perform read-only repository identity discovery. It must
not create a branch or worktree, fork or switch a Pi session, alter the Kitty
tab, write an observation cache, or invoke GitHub. Tests cover the pure record
transition, command delegation, atomic filesystem-store contract, reopen, and
the absence of resource-adapter calls.

### Increment 2: read persisted agents

**User-visible delivery:** restart Pi, run `/agents`, and see the persisted
record as `provisioning` with no resources. Selecting it shows its UUID,
repository, revision, lifecycle, and empty resource list.

This increment adds registry enumeration, repository scoping, schema handling,
and read-only formatting. It performs no repair or external mutation. Tests
cover missing/malformed/unknown-schema files, repository filtering, restart
through a fresh store instance, and deterministic rendering.

### Increment 3: create Worktrunk resources

**User-visible delivery:** the `/agents` creation action now persists intent,
invokes Worktrunk, and records the verified worktree and local-branch
resources. The current Pi process remains in the primary worktree and the
record remains `provisioning`.

This increment introduces the repository lock, operation journal, Worktrunk
adapter, safe argument construction, retry after interruption, and cleanup of
an explicitly abandoned provisioning record. It must not fork/switch the Pi
session, adopt or retitle the Kitty tab, or query GitHub.

### Increment 4: complete clean promotion

**User-visible delivery:** the same creation action continues from the verified
Worktrunk resources, derives the destination Pi session, switches the current
runtime to the target cwd, adopts the same Kitty tab, and changes lifecycle to
`active`.

The source Pi session remains available. The record gains the destination
Pi-session and logical Kitty resources only after each effect is verified.
Tests exercise every interruption boundary and prove that retry resumes the
same agent rather than creating duplicate resources.

### Increment 5: observe and report status

**User-visible delivery:** `/agents` renders the active agent immediately,
then refreshes its status; Pi working/waiting events update the observation
cache, Kitty title, and Worktrunk marker.

This increment adds the observer, disposable cache, per-source freshness
merge, managed identity resolution, and duplicate-tab detection. Tests prove
that cache loss is harmless, older observations cannot overwrite newer ones,
and cached state never authorizes mutation.

### Increment 6: stop and restore

**User-visible delivery:** the user can stop an agent, restart Kitty or the
computer, open Pi in the primary worktree, run `/agents`, and restore the exact
Pi session into its worktree using the configured Kitty template.

This increment adds restoration definitions, focus, idempotent stop/restore,
and reboot recovery. It does not yet add child agents or GitHub behavior.

### Increment 7: child agents

**User-visible delivery:** an active managed agent can create a child with its
own provisioning record, branch, worktree, Pi session, and Kitty tab, and
`/agents` displays the durable hierarchy.

Child creation reuses the same phase model, stores `parentId`, and adds
descendant safety rules without introducing a second agent implementation.

### Increment 8: GitHub and deletion

**User-visible delivery:** `/agents` shows normalized PR state and can present,
confirm, execute, interrupt, and resume exact resource-level deletion and
merged-age cleanup plans.

This increment adds PR ownership/association, structured `gh` observation,
fresh destructive revalidation, idempotent resource journals, and partial
failure reporting.

Only after Increment 8 should development consider richer UI, background
observation, archive, dirty/non-default promotion, or multi-repository control.

## 24. Testing

The normative approach is defined in
[the testing strategy](agents-testing-strategy.md). In summary:

- use Vitest;
- keep reconciliation, planning, cache merging, and operation transitions pure;
- use fake adapters and in-memory/fault-injecting state stores for normal tests;
- use real temporary directories only for narrow durable-store and restart
  recovery contracts;
- use fixture-based adapter parsing and exact argument-array tests;
- keep real Kitty, Worktrunk, GitHub, and Pi UI behavior in a concise manual
  acceptance suite.

### 24.1 MVP acceptance scenarios

1. Start persisted Pi in a clean primary/default worktree and promote it.
1. Verify execution continues in the same tab and target cwd.
1. Verify the source Pi session remains and the destination has a distinct
   Pi-session file linked by transition metadata.
1. Verify Worktrunk marker and Kitty title follow working/waiting events.
1. Stop the agent and retain all durable resources.
1. Restart Kitty, start Pi in the primary worktree, and resume the exact Pi session
   from the configured recipe.
1. Stop two disposable agents, enter a configured resume/restore subcommand,
   verify its picker contains only eligible agents, multi-select both, and
   receive independent outcomes keyed by UUID.
1. Spawn a child and verify independent branch, worktree, Pi session, tab, and
   `parentId`.
1. Kill child Pi ungracefully and reconcile it as stopped rather than working.
1. Create a duplicate tagged tab and verify mutation refusal.
1. Associate an open PR, confirm deletion plan discloses closure, and verify
   the PR is closed—not described as deleted.
1. Plan cleanup for an old merged PR and verify nothing changes before
   confirmation.
1. Interrupt deletion after each resource action and verify retry converges
   without repeating unsafe effects.
1. Change the record/worktree after planning and verify stale execution
   refusal.
1. Verify no operation can target or register the primary worktree.
1. Invoke `/agents` outside a repository and verify the MVP explains that
   multi-repository directory scope is a deferred feature.

## 25. Open implementation choices

These do not block the design:

1. Direct Kitty launch versus native `goto_session` behind the restoration
   adapter.
1. Exact title icons/colors.
1. `ctx.ui.select` versus a small custom list after lifecycle correctness.
1. Whether initial `/agents` uses blocking refresh after cache-first render or
   waits for a custom component before supporting live row updates.
1. Hidden Pi identity entry versus the same visible transition entry used by
   pi-worktrunk.
1. Whether explicit deletion of a live agent automatically performs stop after
   plan confirmation or requires a separate stop first. Automated cleanup must
   always require stopped state.
1. Exact `/agents` subcommand vocabulary, including `resume` versus `restore`
   and the label for entering agent creation. The namespace and interactive
   routing behavior are settled; these words are not.

## 26. References

- [Pi extension API](https://pi.dev/docs/latest/extensions)
- [Pi sessions](https://pi.dev/docs/latest/sessions)
- [Pi RPC mode](https://pi.dev/docs/latest/rpc)
- [Testing strategy](agents-testing-strategy.md)
- [pi-worktrunk](https://github.com/mavam/pi-worktrunk)
- [Worktrunk `wt switch`](https://worktrunk.dev/switch/)
- [Worktrunk `wt remove`](https://worktrunk.dev/remove/)
- [Worktrunk extension hooks](https://worktrunk.dev/extending/)
- [Kitty sessions](https://sw.kovidgoyal.net/kitty/sessions/)
- [Kitty remote control](https://sw.kovidgoyal.net/kitty/remote-control/)
- [GitHub CLI](https://docs.github.com/en/github-cli)
