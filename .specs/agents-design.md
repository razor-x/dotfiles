# Agents: MVP Design Specification

Status: draft for local prototyping\
Audience: Razor X\
Implementation home: `razor-x/dotfiles`\
Extension name: `agents`\
Local extension path: `local/agents`

## 1. Document suite

This document defines the initial implementation. Four additive feature
specifications deliberately remain outside the MVP, and three companion
documents define shared implementation strategy:

- [Archive lifecycle](agents-archive.md): retain a Pi session and
  metadata snapshot while removing the agent's operational resources.
- [Dirty or non-default primary-worktree promotion](agents-transactional-promotion.md):
  transfer staged, unstaged, and untracked state, or move an existing feature
  branch out of the primary worktree.
- [Multi-repository control](agents-multi-repo-control.md): run Pi
  above several repositories and operate on their agents as one management
  scope.
- [Delegation and communication security](agents-delegation-communication.md):
  coordinate managed agents across repositories without allowing unrelated
  delegation trees to communicate or inventing managed controller identities.
- [Testing strategy](agents-testing-strategy.md): use Vitest, a
  functional core, fake adapters, narrow persistence contracts, and manual
  external-system acceptance checks.
- [Kitty remote-control security boundary](agents-kitty-security.md): preserve
  nono confinement through a narrow, default-deny Kitty gateway; this blocking
  companion supersedes direct remote-control and executable restoration-file
  examples in this document.
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
> canonical non-primary Worktrunk worktree, and at most one Kitty tab while
> running.

An agent never moves among worktrees or owns several worktrees. It may use
multiple branches and multiple pull requests sequentially in its one worktree,
with exactly one branch checked out at a time. The current branch is observed
Git state, not agent identity; the canonical worktree path is the durable
worktree binding.

A provisioning record is the durable, potentially incomplete path toward that
invariant and may initially own no resources.

An agent owns a flat list of independently identifiable resources. Branches and
pull requests are plural, independently owned or associated resources. There is
no separate `Workspace` domain object. Stop, restore, delete, and later archive
are idempotent reconciliation operations over that resource list.

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
1. **One agent owns one worktree.** Worktree identity is its canonical path.
   An agent never changes or multiplies that binding; parallel work requiring
   simultaneous checkouts uses separate related agents.
1. **Branches and PRs are plural.** An agent may switch among several branch
   resources and may manage several PR resources sequentially. Current checkout
   is observed state and does not confer ownership.
1. **The primary worktree is never owned.** It is not registered, restored,
   archived, or deleted as an agent resource.
1. **One Kitty tab is one running agent.** Arbitrary tab contents, panes,
   scrollback, editors, and process topology are not persisted.
1. **Restore is semantic.** It creates a new tab using user-managed Kitty
   configuration, changes to the agent worktree, and resumes the exact Pi session.
1. **Worktrunk remains authoritative.** The extension does not implement raw
   worktree lifecycle in parallel or bypass Worktrunk safety behavior.
1. **Agents may have supporting child agents.** “Child” records delegation
   provenance and coordination only. Each child independently owns
   its Pi session, one worktree, branch and PR resources, and live tab, even
   when it works in another repository or on a structurally sibling Git branch.
1. **Delegation never cascades resource ownership.** A parent/child edge cannot
   make one agent own or automatically delete another agent's resources.
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
1. **Lifecycle and orchestration are separate.** `agents` owns identities,
   delegation relationships, resource/status queries, and lifecycle operations.
   Task decomposition, assignment delivery, broadcasts, questions, progress,
   and result collection belong to a communication extension plus an
   orchestration skill.
1. **Root controllers remain unmanaged.** A primary-worktree or
   multi-repository Pi session may coordinate agents without an agent record,
   stable controller ID, synthetic parent node, worktree, or managed resources.
   Agents it creates directly are top-level agents.
1. **Agent communication is ancestry-authorized.** A managed sender's identity
   is transport-authenticated and delivery is code-authorized by following
   manager-assigned `parentAgentId` links, as specified by the
   delegation/communication companion.
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

The UUID—not the name, current branch, worktree path, tab title, PR number, or
Pi filename—is the agent's stable identity. The canonical worktree path is the
stable identity of the one worktree resource, not of the agent itself.

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

### 4.4 Child and supporting agent

A **child agent** is a managed agent whose record has a delegation parent. A
**supporting agent** is a child created to perform delegated work; it may use
another worktree in the same repository, a worktree in another repository, or
a Git-sibling branch/PR.

“Child” describes delegation provenance and coordination only. It does not
mean filesystem containment, repository containment, process containment, or
resource ownership. Parent and child independently own all of their resources.
Relationships use stable agent UUIDs, never paths. The settled fields are
`agentId: AgentId` and `parentAgentId: AgentId | null`; no bare `id` key,
`ControllerId`, or `lineageId` is part of the model. Parentage semantics are
provenance and coordination, not ownership. The MVP creates supporting agents
only in the same repository;
cross-repository creation is specified by the multi-repository feature.

### 4.5 Controller role and management scope

A **controller** is the current Pi process while it coordinates managed agents.
A Pi session in a primary worktree can be a repository-wide controller without
becoming a managed agent, and a managed agent can control itself and its
permitted descendants.

A controller remains an unmanaged Pi session. It receives no agent record,
`ControllerId`, `parentAgentId`, worktree, Pi-session resource, branch, PR, tab,
or restoration lifecycle. Agents it creates directly have
`parentAgentId: null`. A communication layer may provide a locally authorized
operator ingress without representing the controller as an agent or sender in
the delegation forest. Durable grouping of a root controller's work is an
optional orchestration-layer feature.

In the MVP, operations default to the Git repository containing the current
working directory. Directory-derived scopes spanning several repositories are
deferred.

### 4.6 Independent structures

Three structures must remain separate:

1. **Resource ownership:** each managed agent owns one worktree and its own flat
   resource references.
1. **Delegation ancestry:** managed agents form a forest through
   `parentAgentId: AgentId | null`; ancestry is recovered by following that
   chain and may cross repositories.
1. **Git topology:** repositories, worktrees, branches, commits, and PRs relate
   independently of delegation ancestry.

No edge in one structure implies an edge in another. In particular, a child
may work on a Git sibling, and a PR head-branch reference does not create a
workspace aggregate or transfer ownership.

### 4.7 Agent record and observation cache

The **agent record** is durable state describing what the agent is and what it
owns. The **observation cache** is disposable state describing what the
extension most recently saw when it inspected those resources.

The cache may be missing, corrupt, stale, or asynchronously refreshed without
changing agent identity. It is never authoritative for destructive safety
decisions.

### 4.8 Runtime and lifecycle terms

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

### 4.9 Operations

- **Promote:** derive a managed Pi session from the current Pi session, create
  its Worktrunk resources, and continue in the same Kitty tab.
- **Spawn supporting agent:** create a fresh independently managed child agent
  in a new tab; assignment delivery is a separate orchestration operation.
- **Switch branch:** safely change the one branch checked out in the agent's
  worktree without changing agent or worktree identity.
- **Associate:** explicitly record a branch or PR relationship without claiming
  ownership merely from discovery or inspection.
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
1. Spawning a supporting agent with its own worktree, initial branch, Pi
   session, tab, and manager-assigned delegation identity.
1. Switching safely among multiple explicitly owned or associated branches in
   one agent worktree while treating the current branch as observed state.
1. Tracking and inspecting multiple branch and PR resources independently.
1. Seeing working, waiting, stopped, provisioning, and broken status.
1. Seeing agent activity in the Kitty tab title and Worktrunk marker.
1. Stopping an agent without deleting its durable resources.
1. Restoring one or more agents after Pi, Kitty, or the computer restarts.
1. Focusing a live agent's tab.
1. Inspecting each explicit GitHub PR's check, review, closed, and merged state
   on demand.
1. Deleting an explicitly selected agent through a resource-level plan.
1. Closing each owned open PR and resolving each owned branch independently as
   part of confirmed deletion.
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
- make one agent own, move among, or simultaneously use multiple worktrees;
- provide simultaneous branch checkouts inside one agent; parallel checkouts
  require separate related agents;
- infer branch or PR ownership merely because an agent inspected or checked out
  it;
- recursively discover arbitrary unmanaged Pi sessions or repositories;
- persist arbitrary Kitty processes, panes, scrollback, or tab contents;
- keep Pi processes alive through reboot;
- poll GitHub in the background;
- merge pull requests automatically;
- decompose tasks, assign work, broadcast requirements, route questions or
  progress, or collect results; those are orchestration/communication concerns;
- implement an arbitrary inter-agent message bus inside the lifecycle manager;
- deliver a supporting agent's initial assignment or final response directly;
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
| FR-03 | An active managed agent shall bind one stable UUID, one persisted Pi session, exactly one canonical non-primary Worktrunk worktree, one or more explicit branch resources, zero or more PR resources, and at most one live Kitty tab; provisioning may be incomplete. |
| FR-04 | Agent-owned and agent-associated artifacts shall be represented as a flat list of typed resource references, with ownership or association decided independently for every branch and PR.                                                                          |
| FR-05 | The current Pi session shall be promotable when it is persisted, interactive, in the primary worktree, clean, and on the default branch.                                                                                                                            |
| FR-06 | Promotion shall derive a destination Pi session in the target cwd, retain the source Pi session, switch the current runtime, and continue in the same Kitty tab.                                                                                                    |
| FR-07 | A managed agent shall be able to spawn a supporting managed agent with independent resources and a manager-assigned `parentAgentId: AgentId`; an unmanaged controller shall create a top-level agent with `parentAgentId: null`.                                |
| FR-08 | The extension shall expose typed model-callable operations and a direct `/agents` Pi command namespace; `/agents` with no arguments shall open the overview, while recognized subcommands shall deep-link into context-filtered interactive flows.                  |
| FR-09 | Status shall be derived from a complete observation snapshot of Worktrunk, Kitty, Pi-session existence, Git including current checkout, and optionally every registered GitHub PR; cached observations are display hints only.                                      |
| FR-10 | Working/waiting state shall appear in the Kitty tab title and Worktrunk marker while an agent is live.                                                                                                                                                              |
| FR-11 | Stop shall remove the live Kitty tab while retaining the Pi session, worktree, branches, registry record, and restoration definition.                                                                                                                               |
| FR-12 | Restore shall recreate a tab from user-managed Kitty configuration and resume the exact registered Pi session.                                                                                                                                                      |
| FR-13 | Restore, focus, stop, and mutation operations shall use stable agent UUIDs after selection, never guessed titles or branch substrings.                                                                                                                              |
| FR-14 | GitHub state for each explicit PR resource shall be queried through structured `gh` output and normalized independently of display text or the currently checked-out branch.                                                                                       |
| FR-15 | Delete and cleanup shall use plan/confirm/execute with an opaque expiring plan token.                                                                                                                                                                               |
| FR-16 | Every delete plan shall enumerate each PR and local/remote branch effect independently, including closure, removal, or explicit retention when applicable.                                                                                                          |
| FR-17 | “Merged older than N days” shall use fresh `mergedAt` for every relevant PR and an extension-computed cutoff; one old merged PR shall not hide another unresolved PR.                                                                                                |
| FR-18 | Deletion shall be resumable and idempotent after any completed resource action.                                                                                                                                                                                     |
| FR-19 | The agent record shall be removed only after all confirmed resources reach their desired absent state.                                                                                                                                                              |
| FR-20 | Deleting a parent shall never add descendants as implicit candidates; before the parent record disappears, every remaining child's `parentAgentId` shall be resolved by independent deletion, reparenting, or detachment.                                      |
| FR-21 | Durable agent records shall contain `agentId`, manager-assigned `parentAgentId`, repository identity, resource references, ownership, lifecycle intent, revision, and timestamps but no authoritative observed status.                                             |
| FR-22 | Each agent may have a separate disposable observation-cache record tied to the current agent revision and resource fingerprint.                                                                                                                                     |
| FR-23 | Missing, malformed, unknown-schema, revision-mismatched, or fingerprint-mismatched observation caches shall be ignored and rebuilt by observation.                                                                                                                  |
| FR-24 | Every destructive plan and execute operation shall obtain fresh observations after acquiring its required locks and shall never rely on cached safety conclusions.                                                                                                  |
| FR-25 | Worktrunk hooks, if configured, shall only request full repository reconciliation; they shall not directly mutate agent resources or apply lifecycle deltas.                                                                                                        |
| FR-26 | The agent-creation flow shall atomically persist a revision-zero `provisioning` agent record with an empty resource list before its first external resource mutation, and creation shall be resumable from that durable intent.                                     |
| FR-27 | `/agents` subcommands shall be UI routes rather than mutation authority: each route shall derive eligible agents from the current scope, resolve selections to stable UUIDs, and invoke the same typed application operations used by the model-callable interface. |
| FR-28 | Batch-appropriate `/agents` flows shall be able to use interactive multi-selection and shall report independent per-agent outcomes; destructive flows shall still use their required plan/confirm/execute protocol.                                                 |
| FR-29 | The canonical worktree path shall identify an agent's one durable worktree binding; neither the initial branch nor the currently checked-out branch shall form durable agent identity.                                                                                |
| FR-30 | Exactly one branch may be checked out in an active agent worktree at a time, and that current branch shall be observed rather than stored as authoritative record state.                                                                                                 |
| FR-31 | Branch switching shall use an exact argument-array `git switch` adapter only after fresh clean-worktree, no-in-progress-operation, target-ref, and cross-worktree-topology checks under the repository lock.                                                            |
| FR-32 | Inspecting, discovering, or checking out a branch or PR shall not by itself create ownership; association or adoption shall be an explicit durable decision.                                                                                                              |
| FR-33 | Cleanup shall resolve every owned/associated branch and PR independently and shall remove the worktree only after those resources have a confirmed terminal disposition.                                                                                                 |
| FR-34 | `parentAgentId` shall be assigned and changed only by manager code from authenticated creation context; model-callable creation inputs shall not accept an arbitrary parent agent ID.                                                                                 |
| FR-35 | The `agents` extension shall expose lifecycle, identity, delegation, resource/status query, resume, stop, and delete operations while leaving assignment and conversational message delivery to the separate orchestration/communication layer.                          |

### 7.2 Safety requirements

| ID    | Requirement                                                                                                                                                                                     |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SR-01 | The extension shall never invoke Worktrunk or Git force-removal options.                                                                                                                        |
| SR-02 | Model-provided paths, titles, names, branch strings, or shell fragments shall never flow directly into destructive commands.                                                                    |
| SR-03 | Destructive operations shall revalidate topology, ownership, cleanliness, liveness, and plan freshness after acquiring locks.                                                                   |
| SR-04 | A dirty, live, current, primary, ambiguous, broken, unknown-schema, or unpushed agent shall be ineligible for automated cleanup.                                                                |
| SR-05 | A branch or PR that is merely discovered, inspected, or checked out shall not be modified as an owned resource without an explicit association/adoption decision and disclosed plan action.                                                                  |
| SR-06 | A GitHub PR record shall never be described as deleted; an open PR may only be closed. Historical merged/closed PRs remain on GitHub.                                                           |
| SR-07 | Missing resources count as idempotent success only when a confirmed operation previously established the exact identity and intended removal. Pre-existing unexplained absence is broken state. |
| SR-08 | The current Pi process shall never delete the agent it is actively running as.                                                                                                                  |
| SR-09 | Delegation relationships shall never cause implicit cascading deletion, archive, branch mutation, PR mutation, or worktree removal.                                                                 |
| SR-10 | Knowing an agent UUID, name, session path, worktree path, branch, tab, or transport address shall grant no communication or lifecycle authority; unmanaged controller authority is not represented by a forgeable controller ID.                              |

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

| Concern                              | Authority                         | Extension responsibility                                              |
| ------------------------------------ | --------------------------------- | --------------------------------------------------------------------- |
| Pi session and model history         | Pi JSONL                          | Record the exact file and resume it                                   |
| Worktree identity/topology           | Git + Worktrunk                   | Bind one canonical path, invoke Worktrunk, validate, never force       |
| Current branch checkout              | Git                               | Observe it and switch safely; never use it as durable agent identity   |
| Local and remote branches            | Git / Git remote                  | Record each association/ownership and delete only when planned         |
| Live terminal topology               | Kitty                             | Discover, tag, create, focus, title, and close tabs                   |
| Pull requests                        | GitHub                            | Query each explicit PR; close only through a confirmed owned action    |
| Managed identity and delegation      | Agent manager                     | Persist `agentId` and manager-assigned `parentAgentId`                  |
| Communication sender/route authority | Authenticated transport capability | Derive sender and enforce ancestry; never trust message-body assertions |
| Working/waiting signal               | Pi lifecycle events               | Report to Kitty and Worktrunk; cache the latest observation            |
| Last observed external state         | Disposable observation cache      | Render quickly, track freshness/errors, and rebuild at any time        |

The registry binds unrelated identifiers; it does not replace any underlying
authority.

### 8.1 Flat resource model

Repository identity and agent metadata are not resources. Everything the agent
may create, retain, close, or remove is represented as an independent resource
reference:

```ts
type ResourceRelationship = "owned" | "associated";

type AgentResourceRef =
  | {
      kind: "pi-session";
      path: string;
      ownership: "owned";
    }
  | {
      kind: "worktree";
      path: string;
      ownership: "owned";
    }
  | {
      kind: "local-branch";
      name: string;
      ownership: ResourceRelationship;
    }
  | {
      kind: "remote-branch";
      remote: string;
      name: string;
      ownership: ResourceRelationship;
    }
  | {
      kind: "pull-request";
      nameWithOwner: string;
      number: number;
      headBranch: {
        repositoryNameWithOwner: string;
        refName: string;
      };
      ownership: ResourceRelationship;
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

The one-worktree cardinality rule applies to the `worktree` resource only:
exactly one canonical path. An active record also has at least one explicit
local branch resource; local branches, remote branches, and pull requests are
otherwise plural.
The worktree resource contains no branch field because the current checkout is
observed state and can change without changing durable worktree identity.

The list remains flat even when one resource references another. A PR's
`headBranch` is an explicit Git relationship for observation and cleanup
ordering; it neither contains that branch resource nor transfers ownership.
Dependency ordering belongs to the reconciliation plan, not to a nested
ownership model.

`associated` means the extension has an explicit durable relationship but is
not authorized to mutate the resource as owner. A confirmed plan may explicitly
adopt one associated branch or PR for that operation. Discovery, inspection, a
matching name, a PR head reference, or current checkout is insufficient for
silent association or mutation. Ownership is decided per resource and is never
inherited from the agent's worktree, PR, parent, or child.

Kitty tab IDs are never persisted. The logical tab resource is discovered by
the agent UUID stored as a Kitty user variable.

## 9. Architecture

The same global extension loads into each Pi process:

```text
Current Pi process
  lifecycle reporter for itself, when managed
  model-callable agent-management tool
  /agents command and list UI
  lifecycle application service
    registry and operation journal
    observer, observation cache, and reconciler
    resource planner and operation reducer
    Pi session adapter
    Worktrunk adapter
    Kitty adapter
    Git/GitHub adapter
```

There is no resident lifecycle controller. Durable agent records can be listed
immediately with their last cached observations. Runtime truth is reconstructed
whenever a management operation or `/agents` refresh observes the external
systems.

Task orchestration sits above this extension:

```text
orchestration skill
  task decomposition, coordination policy, result synthesis
    |
inter-agent communication extension
  authenticated assignment/update/question/result delivery
    |
agents extension
  identity, delegation, resource/status query, lifecycle
```

Pi's `pi.events` bus is process-local and is not an inter-agent transport.
`pi.sendUserMessage()` can be the final in-process delivery sink only after a
separate transport has authenticated and authorized the sender. The lifecycle
extension does not parse message bodies to establish identity or authority.

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
type AgentId = string;

type ManagedAgentRecordV1 = {
  schemaVersion: 1;
  agentId: AgentId;
  revision: number;
  name: string;
  parentAgentId: AgentId | null;

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
- Once lifecycle is `active`, resource-kind cardinalities require exactly one
  owned `pi-session`, exactly one owned canonical `worktree`, one or more local
  branch resources, zero or more remote branch/PR resources, and at most one
  logical live tab.
- Neither the initial branch nor current checkout is stored on the worktree
  resource or used as agent identity. Current checkout belongs in fresh/cached
  Git observation.
- A `provisioning` record may initially have `resources: []`. It represents
  durable creation intent before the first external effect, not an active
  agent with missing resources.
- During provisioning, resources are appended only after their corresponding
  effects are verified. A fresh supporting agent may therefore temporarily
  lack its `pi-session` resource and adds it immediately after Pi creates the
  session.
- `parentAgentId` is assigned by manager code from authenticated creation
  context. A managed caller normally becomes the parent; an unmanaged
  controller creates a top-level agent with `parentAgentId: null`. Models
  cannot choose or alter the field, and it never conveys ownership.
- Reparenting/detachment is an explicit manager operation. The manager updates
  affected `parentAgentId` links and rotates communication capabilities
  atomically; record-file edits are not authorization evidence.
- Branch and PR identity plus per-resource ownership belong in `resources`;
  current checkout and changing PR status belong in the observation cache.
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
      canonicalPath: string | null;
      isPrimary: boolean;
    }>;
    git?: SourceObservation<{
      clean: boolean;
      currentBranch: string | null;
      head: string | null;
      branches: Array<{
        scope: "local" | "remote";
        remote?: string;
        name: string;
        exists: boolean;
        checkedOutInWorktree?: string;
      }>;
      unpushedCommits: boolean | null;
    }>;
    kitty?: SourceObservation<{
      matchingTabs: number;
    }>;
    github?: SourceObservation<PullRequestStatus[]>;
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

These are recovery aids. The registry remains the canonical resource binding.
They are not communication credentials, and the absence of a branch field is
intentional: switching branches does not change managed identity.

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
1. Inspect the current checkout plus every explicit local and remote branch
   resource when relevant.
1. Query each explicit PR resource only when requested or required by policy.
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
agent is stopped regardless of its last Pi event. Detached HEAD, no current
branch, more than one checkout claim for the same worktree, or a current branch
that was switched manually without an explicit resource relationship is a
reported topology mismatch; reconciliation does not silently associate it.

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

- validates cwd, Pi-session path, repository, and exact canonical registered
  worktree path;
- observes the current branch without treating it as identity;
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

### 13.3 Supporting-agent startup

A fresh supporting-agent tab starts ordinary interactive Pi with identity but
without a task-bearing initial prompt:

```text
PI_MANAGED_AGENT_ID=<uuid> pi --name <name>
```

The child extension obtains the Pi-session path, appends it to the resource
list, and changes the agent from `provisioning` to `active`. If registration
does not complete before a short timeout, retain all created resources and show
an error; the user may be at a trust, authentication, or login prompt.

Initial assignment is delivered only after registration by the separate,
authenticated communication layer, which may use `pi.sendUserMessage()` as the
local Pi delivery mechanism. Lifecycle creation neither embeds the task in
process arguments nor accepts a message-body sender identity.

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
- remove by exact reconciled canonical worktree path;
- report worktree and checked-out-branch outcomes independently even if a
  Worktrunk command couples their physical effects;
- treat an owned branch planned for removal as unfinished until its exact ref
  is absent, while an explicitly associated/retained branch may be a successful
  terminal disposition.

Extension-specific Worktrunk hooks, if added, request complete observation
and reconciliation only. They do not directly patch an agent record. Hooks
owned by the repository may continue performing their normal setup or cleanup
work as part of the Worktrunk command.

Ignored-file copying, dependency installation, dev servers, and project setup
remain Worktrunk hook/configuration concerns.

### 14.1 Git branch switching

Branch switching occurs inside the existing worktree and does not call
Worktrunk creation/removal:

```ts
interface GitBranchAdapter {
  observeCheckout(worktreeCwd: string): Promise<CheckoutObservation>;
  switchBranch(worktreeCwd: string, branch: string): Promise<SwitchOutcome>;
}
```

The production adapter invokes `git switch -- <exact-validated-branch>` with an
argument array. Before and after the effect, the application service verifies:

- the worktree canonicalizes to the agent's one registered worktree;
- the worktree is clean and has no merge, rebase, cherry-pick, revert, bisect,
  or conflict in progress;
- the target is an exact local branch resource already recorded as owned or
  associated, or has first gone through an explicit association operation;
- the target is not checked out in another worktree and switching would not
  disturb primary/managed worktree topology;
- the observed current branch changes as expected.

Inspection, checkout, or a PR head reference does not promote an associated
branch to owned. A parallel task requiring both branches checked out at once
must create another related agent with its own worktree.

## 15. Kitty integration

> **Blocking security constraint:**
> [Kitty remote-control security boundary](agents-kitty-security.md) supersedes
> direct standard remote-control calls, bare Pi launch, and executable Kitty
> restoration files described below. The trusted host launcher is `pi-nono` in
> these dotfiles; nono remains an outer compatibility layer rather than an
> extension responsibility. Treat the remainder of this section as product
> intent until it is amended during the secure-gateway implementation.

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

Fresh supporting-agent startup may use a separate template because its
Pi-session path is unknown until Pi starts. It carries identity and display data
only, not parent/lineage or assignment data. Once registered, the durable
restoration definition is rendered with the exact Pi-session path.

## 16. GitHub integration

For each explicit PR resource, the GitHub adapter runs `gh` with the exact base
repository and PR number (using the agent worktree only as a safe cwd) and
normalizes:

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

An agent's GitHub observation is a collection keyed by
`(nameWithOwner, number)`, not one status inferred from the current branch.
Short in-memory caching is allowed for display. Authentication failure, network
failure, absent `gh`, or a non-GitHub remote becomes `unknown` for the affected
resource and does not corrupt local management. Merely inspecting a PR does not
append it to the durable resource list.

For age policies, the model supplies a duration such as
`mergedOlderThanDays: 7`; extension code computes the timestamp cutoff and
checks every relevant PR independently.

## 17. User-facing Pi API

### 17.1 Model-callable tool

Begin with one action-discriminated tool named `agents`:

```text
list
inspect
promote
spawn_child
associate_branch
associate_pull_request
switch_branch
restore
focus
stop
delete_plan
delete_execute
cleanup_plan
cleanup_execute
```

Mutation actions accept agent UUIDs after selection and exact resource
identities returned by inspect/association. Names and unregistered branch
strings are search keys only; ambiguity returns candidates rather than
guessing. `spawn_child` is operation vocabulary only: its relationship is
delegation, and model-callable inputs never accept a raw `parentAgentId` value.

Tool guidance shall require:

- current-repository scope in the MVP;
- explicit freshness metadata whenever list/inspect returns cached observations;
- plan actions before destructive execute actions;
- adapter evidence before claiming success;
- no shell-command fallback after a managed operation refuses;
- no task/message payload in lifecycle creation and no claim that `agents`
  delivered an assignment or collected a result.

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
1. groups agents by delegation relationship (without implying ownership) and
   renders cached status with per-source freshness;
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
1. Create an `agentId` with `parentAgentId: null` and atomically write the
   revision-zero provisioning agent record with `resources: []`.
1. Create a provisioning operation record referring to that agent.
1. Create the requested Worktrunk branch/worktree from the recorded HEAD.
1. Verify the result, then append the canonical worktree and owned initial
   local-branch resource references independently under an expected-revision
   write.
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
worktree and initial branch are unchanged and exclusively created by it.
Otherwise preserve both independently identified resources and an exact
recovery record.

The refusal for advanced cases points to the separate promotion feature.

### 18.2 Spawn supporting agent

Model-callable inputs:

- name;
- new initial branch;
- optional base, defaulting to the caller's current HEAD in the same repository.

There is no task prompt or arbitrary parent-agent-ID input. The manager derives
the caller from the current registered managed-agent identity. In the MVP a
managed caller becomes the delegation parent; an unmanaged primary-worktree
controller creates a top-level agent with `parentAgentId: null`. The MVP
requires parent and child to share a repository.

Sequence:

1. Validate repository, base, initial-branch absence, caller authority, and the
   manager-derived delegation relationship.
1. Create an `agentId` and manager-assigned `parentAgentId`, persist an empty
   provisioning record, and create its operation record.
1. Create and verify the Worktrunk worktree, then append the canonical worktree
   and owned initial-local-branch resource references independently.
1. Render and verify the restoration definition, then append its resource
   reference.
1. Launch the configured fresh supporting-agent Kitty tab with UUID, cwd, and
   name, but no assignment body.
1. Verify the tagged tab, append its logical resource, and leave the delegating
   tab focused unless configured otherwise.
1. Let the child register its Pi-session resource and finalize activation.
1. Invalidate the provisioning cache when the durable resource revision changes
   and observe the active child, including its current branch.

No task delivery or conversational result routing is implied by parentage. An
orchestration layer sends the initial assignment only after authenticated child
registration.

### 18.3 Associate and switch branch

Association records a relationship without claiming ownership:

1. inspect the exact candidate ref and all worktree checkouts;
1. present whether it already exists, where it is checked out, and whether the
   requested relationship is `associated` or an explicit ownership adoption;
1. persist the branch resource only after confirmation/manager authorization;
1. do not derive association from discovery, a matching PR, or checkout alone.

Switching then:

1. acquires the agent and repository locks;
1. freshly verifies the agent's canonical worktree, clean state, absence of an
   in-progress Git operation, exact registered target branch, and topology;
1. invokes `git switch -- <validated-branch>` through the typed adapter;
1. observes and verifies exactly one current checkout in that worktree;
1. updates only the observation cache unless an explicit association/adoption
   was separately confirmed.

The operation never changes agent UUID, repository identity, worktree resource,
or delegation relationship.

### 18.4 Restore

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

### 18.5 Stop

Stop is idempotent removal of the logical live-tab resource:

1. Discover by managed UUID.
1. If absent, report already stopped.
1. Refuse duplicate matches.
1. Request graceful Pi shutdown when practical, then close the tab.
1. Confirm absence, clear the Worktrunk marker, and merge a stopped Kitty/Pi
   observation into the cache.

It does not kill arbitrary processes in the worktree. Worktrunk tethering owns
processes intentionally coupled to worktree lifetime.

### 18.6 Focus

Focus resolves a live tab by UUID. If stopped, it offers restore rather than
silently starting the agent. It never matches by mutable title alone.

### 18.7 Delete planning

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
    | "release-association"
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
    agentId: AgentId;
    recordRevision: number;
    reason: string;
    actions: ResourceAction[];
  }>;
  excluded: Array<{ agentId: AgentId; reason: string }>;
};
```

For every PR resource, the plan must state that an open PR will be **closed**,
not deleted, or that an associated PR will be retained and its association
released. Merged and already-closed PR records are preserved as GitHub history
and require no external mutation.

Execute accepts only the token; it cannot add agent IDs, paths, or actions.
After locks, it revalidates record revisions, topology, liveness, cleanliness,
unpushed commits, every branch and PR, delegation-edge integrity, GitHub state,
and every adopted ownership decision. Selecting a parent never adds a child to
the plan. A blocking child must first be independently deleted, reparented, or
detached; independently selected parent/child candidates are each displayed
and confirmed in their own right.

### 18.8 Idempotent delete execution

Per agent, execution uses dependency ordering but retains a flat resource
model:

1. mark the independently selected agent `deleting` and create an operation
   journal;
1. close the live tab if the explicit plan allows deleting a previously live
   agent; automated cleanup otherwise requires it already stopped;
1. close each confirmed, still-open owned/adopted PR independently;
1. remove each confirmed owned/adopted remote branch independently;
1. resolve every local branch independently: delete owned non-current branches,
   retain/release associated branches without mutation, and record the exact
   disposition of the currently checked-out branch;
1. only after every PR and branch has a confirmed terminal disposition, remove
   the exact worktree through Worktrunk; if Worktrunk couples removal of the
   checked-out branch, journal and verify the branch and worktree as separate
   resource outcomes;
1. remove the generated Kitty restoration definition;
1. move the Pi-session file to trash when available, otherwise unlink only
   under the confirmed plan;
1. remove the disposable observation cache;
1. verify every planned resource reached its absent, closed, or explicitly
   retained/released terminal state;
1. remove the agent record last.

After each action, persist completion in the operation journal. A retry does
not repeat completed effects:

- missing tab: success;
- each PR already closed or merged: success for that exact PR;
- each remote/local branch already absent: success only for the exact journaled
  branch action;
- an associated branch/PR explicitly retained and released from the agent
  record: success without external mutation;
- Worktrunk worktree already absent: success only when the journal proves the
  exact worktree effect and every coupled branch outcome;
- observation cache already absent: success;
- Pi session already trashed by this plan: success.

If an action fails, retain the agent record, all remaining resources, the
operation journal, and the exact next action. There is no cross-system rollback.

### 18.9 Policy cleanup

“Delete agents with PRs merged more than N days ago” is selection followed by
ordinary per-agent deletion.

Eligibility requires:

- at least one explicit PR resource;
- every explicit PR has fresh, unambiguous GitHub state and is `MERGED`;
- every `mergedAt` precedes the extension-computed cutoff, so one old PR cannot
  hide a newer, open, closed-unmerged, or unknown PR;
- no live tab;
- worktree is clean;
- no unpushed commits or unique untracked data on any owned branch scheduled
  for removal;
- every branch and PR has an independently safe terminal disposition;
- every child edge is already resolved or the child was independently selected
  by the same policy and explicitly confirmed;
- agent is not current, primary, provisioning, deleting, broken, or unknown
  schema.

The policy never adds descendants merely because their parent qualified. When
parent and child independently qualify, children execute first only to preserve
relationship integrity. Failure of one agent is reported independently and
does not make successful deletions appear rolled back.

## 19. Safety invariants

1. The primary worktree can never appear in an agent's resource list.
1. An active agent has exactly one canonical owned worktree and never changes
   that binding; simultaneous checkouts require separate agents.
1. Current branch is observed state, never durable agent identity or implicit
   ownership.
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
1. A discovered branch or PR must be explicitly associated/adopted and present
   in the confirmed action plan before mutation.
1. Delegation edges never cascade resource deletion; relationship integrity is
   resolved separately from each agent's resource plan.
1. Communication authority comes from a manager-registered connection or
   capability and ancestry checks, never names, paths, addresses, or message
   bodies.
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
    focusNewSupportingAgents: false,
  },
  github: { cacheMs: 45_000 },
  observations: {
    localStaleAfterMs: 10_000,
    githubStaleAfterMs: 60_000,
  },
  planTtlMs: 5 * 60_000,
  supportingAgentStartupTimeoutMs: 15_000,
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
    associate.ts
    switch-branch.ts
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
  delegation/
    relationships.ts
    authorization.ts
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

### 22.4 Delegation and communication seam

- Every agent has a manager-assigned `parentAgentId`, independent of repository
  and resource ownership; ancestry is derived by following parent links.
- Root controller Pi sessions remain unmanaged and receive no controller record
  or stable controller ID.
- Creation APIs derive relationships from authenticated caller context rather
  than model-provided agent IDs.
- Lifecycle APIs return stable IDs and resource/status data suitable for a
  separate communication extension and orchestration skill.
- Pi's process-local event bus and message-injection APIs are not treated as
  sender authentication.

The MVP does not implement cross-process messaging, assignment delivery,
progress/result collection, peer grants, or durable orchestration groups. The
blocking authorization rules are in
[the companion specification](agents-delegation-communication.md).

### 22.5 Asynchronous-observation seam

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
`parentAgentId: null`, and `resources: []`.

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
invokes Worktrunk, and records the verified canonical worktree and owned
initial-local-branch resources independently. The current Pi process remains in
the primary worktree and the record remains `provisioning`.

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
merge, managed identity resolution, current-branch observation, and
duplicate-tab detection. Tests prove that cache loss is harmless, older
observations cannot overwrite newer ones, branch switching does not alter agent
identity, and cached state never authorizes mutation.

### Increment 6: stop and restore

**User-visible delivery:** the user can stop an agent, restart Kitty or the
computer, open Pi in the primary worktree, run `/agents`, and restore the exact
Pi session into its worktree using the configured Kitty template.

This increment adds restoration definitions, focus, idempotent stop/restore,
and reboot recovery. It does not yet add supporting agents or GitHub behavior.

### Increment 7: supporting agents and delegation

**User-visible delivery:** an active managed agent can create a supporting
agent with its own provisioning record, initial branch, worktree, Pi session,
and Kitty tab, and `/agents` displays delegation ancestry without implying
resource ownership.

Creation reuses the same phase model, stores manager-assigned
`parentAgentId`, supplies no assignment prompt, and adds
relationship-integrity rules without introducing a second agent implementation
or cascading cleanup.

### Increment 8: sequential branches and PR associations

**User-visible delivery:** one active agent can explicitly associate and switch
among several branches in its one worktree, and inspect several explicit PR
resources independently.

This increment adds the typed `git switch` adapter, clean/topology preflight,
current-checkout observation, plural branch/PR resource presentation, and tests
that discovery/checkout does not confer ownership.

### Increment 9: GitHub and deletion

**User-visible delivery:** `/agents` shows normalized state for every explicit
PR and can present, confirm, execute, interrupt, and resume exact per-resource
deletion and merged-age cleanup plans.

This increment adds per-PR ownership/association, structured `gh` observation,
independent branch/PR dispositions, non-cascading relationship checks, fresh
destructive revalidation, idempotent resource journals, and partial failure
reporting.

Only after Increment 9 should development consider richer UI, background
observation, archive, dirty/non-default promotion, multi-repository control, or
inter-agent communication.

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
1. Spawn a supporting agent and verify independent initial branch, worktree, Pi
   session, tab, manager-assigned `parentAgentId`, and no lifecycle-delivered
   assignment prompt.
1. Kill the child Pi ungracefully and reconcile it as stopped rather than
   working.
1. Associate a second branch, switch to it with a clean worktree, and verify the
   UUID and canonical worktree binding remain unchanged while current-branch
   observation changes.
1. Attempt the same switch while dirty or while the target is checked out in
   another worktree and verify refusal before mutation.
1. Inspect an unregistered branch/PR and verify inspection alone creates no
   owned or associated resource.
1. Create a duplicate tagged tab and verify mutation refusal.
1. Associate two PRs, confirm deletion plans disclose each independent
   disposition, and verify an owned open PR is closed—not described as deleted.
1. Plan cleanup with one old merged PR plus one unresolved PR and verify the
   agent is excluded; after both are old and merged, verify nothing changes
   before confirmation.
1. Select a parent for deletion and verify a remaining child blocks it without
   becoming an implicit candidate; then detach/reparent or independently select
   the child and retry.
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
1. Exact `/agents` subcommand vocabulary, including `resume` versus `restore`,
   `spawn_child` versus `spawn_supporting_agent`, branch-association wording,
   and the label for entering agent creation. The namespace and interactive
   routing behavior are settled; these words are not.
1. How an optional orchestration layer groups work initiated by an unmanaged
   root controller without adding a controller record or workspace aggregate.

## 26. References

- [Pi extension API](https://pi.dev/docs/latest/extensions)
- [Pi sessions](https://pi.dev/docs/latest/sessions)
- [Pi RPC mode](https://pi.dev/docs/latest/rpc)
- [Testing strategy](agents-testing-strategy.md)
- [Delegation and communication security](agents-delegation-communication.md)
- [pi-worktrunk](https://github.com/mavam/pi-worktrunk)
- [Worktrunk `wt switch`](https://worktrunk.dev/switch/)
- [Worktrunk `wt remove`](https://worktrunk.dev/remove/)
- [Git `switch`](https://git-scm.com/docs/git-switch)
- [Worktrunk extension hooks](https://worktrunk.dev/extending/)
- [Kitty sessions](https://sw.kovidgoyal.net/kitty/sessions/)
- [Kitty remote control](https://sw.kovidgoyal.net/kitty/remote-control/)
- [GitHub CLI](https://docs.github.com/en/github-cli)
