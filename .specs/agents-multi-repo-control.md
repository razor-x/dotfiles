# Agents: Multi-Repository Control Feature Specification

Status: deferred feature specification\
Depends on: `agents-design.md` MVP\
Working feature name: directory-scoped control

## 1. Purpose

The MVP manages agents for the repository containing the current Pi process.
This feature allows an ordinary Pi session to run in a directory containing
several repositories and apply the same model across them:

> “Show me all agents under this directory.”

> “Restore the stopped agents in these repositories.”

> “Clean up agents with PRs merged more than a week ago across all of them.”

This is a scope and lifecycle-coordination extension, not a new kind of agent.
Every active managed agent still owns one Pi session, exactly one canonical
non-primary Worktrunk worktree, plural explicit branch/PR resources, and at most
one live Kitty tab; exactly one branch is checked out as observed state.
Provisioning records may be incomplete. Resource reconciliation remains
per-agent and repository mutation remains per-repository.

## 2. Simple extension path

The MVP already stores all per-user agent records in one globally enumerable
registry and includes canonical repository identity in every record. This
feature adds:

1. a typed directory management scope derived from the current cwd;
1. selection of registered agents whose primary repositories are beneath that
   directory;
1. immediate repository-grouped presentation from per-agent observation
   caches;
1. bounded asynchronous refresh using complete repository observations;
1. batch plans containing independent per-agent resource operations.

It does not require:

- a daemon;
- a database migration;
- a workspace aggregate;
- turning a controller into a managed agent or resource owner;
- durable orchestration grouping merely to resolve a directory scope;
- a distributed transaction across repositories;
- scanning or indexing arbitrary unmanaged Pi sessions.

The parent-directory Pi session remains ordinary and unmanaged while acting in
a controller role. Lifecycle management does not register, own, restore, or
make it a delegation parent, and communication does not mint a `ControllerId`
or `lineageId`. Agents it creates directly are top-level agents with
`parentAgentId: null`. A locally authorized operator ingress may deliver
assignments without adding a controller node or workspace aggregate.

Scope membership comes only from durable agent records. Cached repository or
resource observations can improve initial display but can never add an agent
to scope, remove it from scope, or authorize a mutation.

## 3. Terminology

### 3.1 Management scope

A transient, resolved set of repositories and agents against which one
operation runs. Scope controls selection; it does not own resources and is not
persisted as another domain entity.

### 3.2 Repository scope

Exactly one canonical Git repository, identified by its Git common directory.
This is the only MVP scope.

### 3.3 Directory scope

All registered repositories whose canonical primary-worktree paths are strict
descendants of a selected directory, plus the directory itself if it is a
repository and the user explicitly includes it.

Directory containment is evaluated on canonical paths. Agents are selected by
their repository's **primary worktree**, not by the possibly external location
of their managed Worktrunk worktree.

### 3.4 Explicit repository scope

A user-selected set of canonical repository IDs. This is useful when the
desired repositories do not share a convenient parent or when a directory
contains unrelated repositories.

### 3.5 Controller Pi session

The current Pi session while it invokes management operations. “Controller” is
a role, not a managed-agent type or stored identity. It has no `ControllerId`,
`parentAgentId`, Pi-session resource, repository, worktree, branch, PR, or tab.
Communication from that session is operator-origin delivery, not an agent
sender inserted into the delegation forest.

## 4. Scope resolution

```ts
type ManagementScope =
  | {
      kind: "repository";
      repositoryCommonDir: string;
    }
  | {
      kind: "directory";
      root: string;
      repositoryCommonDirs: string[];
    }
  | {
      kind: "repositories";
      repositoryCommonDirs: string[];
    };
```

Default behavior:

1. If cwd is inside a Git worktree, default to that canonical repository.
1. If cwd is outside a Git repository, offer directory scope rooted at cwd.
1. If cwd is itself a repository containing nested repositories, default to
   repository scope and require an explicit switch to directory scope.
1. Explicit repository selection overrides cwd-derived defaults.

The resolved scope is copied into list results and destructive plan records so
later cwd changes cannot silently alter the operation.

## 5. Repository identity and Worktrunk deduplication

Repository identity must not be inferred from directory names or GitHub remote
names. The adapter resolves:

```ts
type RepositoryIdentity = {
  commonDir: string;
  primaryWorktree: string;
  githubNameWithOwner?: string;
};
```

`commonDir` and `primaryWorktree` are canonical absolute paths. Git worktrees
belonging to the same common directory are one repository.

This prevents a directory controller from treating Worktrunk worktrees as
additional repositories when they happen to be stored beneath the directory
root. Scope membership uses the primary-worktree path; reconciliation then
uses Worktrunk to enumerate all worktrees for that repository.

Remote identity is display and GitHub-query metadata. Two local clones of the
same GitHub repository remain two distinct local repository identities unless
the user explicitly decides otherwise.

## 6. Registry-first discovery

Routine status, restore, stop, and cleanup do not need to scan the filesystem.
They select existing agent records from the global registry by canonical path
containment.

This means a repository with no managed agents need not have representation in
the extension. To create an agent in such a repository, the user supplies or
selects its path, and the extension canonicalizes it at that time.

Optional repository discovery may be added for a repository picker, but it is
not part of the core feature and must be bounded:

- scan only a user-selected/configured root;
- do not follow symlinked directory trees by default;
- do not cross filesystem boundaries by default;
- exclude `.git`, Worktrunk-managed worktree roots already recognized,
  dependency caches, and configured paths;
- use an explicit depth or time bound;
- canonicalize every candidate through Git before display;
- never perform recursive discovery as a side effect of a destructive command.

## 7. Goals

The feature must support:

1. Listing agents across registered repositories beneath cwd.
1. Grouping status and errors by repository.
1. Inspecting, focusing, stopping, and restoring selected agents across those
   repositories.
1. Planning and executing cleanup policies across several repositories.
1. Targeting a particular repository when spawning a new top-level agent.
1. Preserving per-agent resource ownership and idempotence.
1. Reporting partial batch outcomes without implying cross-repository
   rollback.
1. Creating supporting agents in a repository different from their managed
   parent while preserving global `agentId`/`parentAgentId` ancestry; an
   unmanaged controller may instead create a top-level agent.

## 8. Non-goals

This feature does not:

- turn the parent-directory Pi session into a managed agent or invent an
  internal controller identity for it;
- give that Pi session a synthetic worktree, repository, or resource list;
- infer delegation children merely from directory scope or lifecycle control;
- make one agent own several repositories or worktrees;
- create a multi-repository workspace object;
- provide atomic commit/rollback across repositories;
- discover all Git repositories or unmanaged Pi sessions on the machine;
- synchronize changes, commits, branches, or PRs between repositories, or
  infer Git topology from delegation ancestry;
- infer a monorepo or dependency graph;
- coordinate merges or releases across repositories;
- preserve or restore the parent-directory controller Pi session as an agent
  resource;
- promote a Pi session outside a repository without first selecting a target
  repository and a separately specified continuation behavior.

## 9. Normative requirements

| ID    | Requirement                                                                                                                                                                                |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| MR-01 | Multi-repository control shall reuse the MVP managed-agent and flat-resource schemas without introducing a new agent kind.                                                                 |
| MR-02 | The active per-user registry shall be globally enumerable and every agent shall carry canonical repository common-dir and primary-worktree identity.                                       |
| MR-03 | A directory scope shall select repositories by canonical primary-worktree containment under the resolved directory root.                                                                   |
| MR-04 | Worktrunk worktrees sharing a Git common directory shall be deduplicated as one repository.                                                                                                |
| MR-05 | The current parent-directory Pi session shall remain unmanaged unless separately promoted; it shall receive no controller record or stable controller ID, and agents it creates directly shall have `parentAgentId: null`. |
| MR-06 | A scope shall be resolved to immutable repository IDs before a destructive plan is presented.                                                                                              |
| MR-07 | Multi-repository deletion and cleanup shall produce one plan grouped by repository and agent with exact resource-level actions.                                                            |
| MR-08 | Plan execution shall revalidate and lock each repository independently immediately before its mutations.                                                                                   |
| MR-09 | A failure in one repository shall not roll back successful actions in another and shall not prevent accurate per-agent outcomes.                                                           |
| MR-10 | Existing-agent listing and cleanup shall be registry-first and shall not recursively scan the filesystem.                                                                                  |
| MR-11 | Unknown or moved repository paths shall be reported as broken bindings and shall not be guessed from matching remote names.                                                                |
| MR-12 | Model-supplied arbitrary directory paths shall not flow directly into destructive scope selection. Scope roots shall originate from cwd, configuration, or explicit UI selection.          |
| MR-13 | Git, Worktrunk, Kitty, and `gh` subprocess concurrency shall be bounded and observable.                                                                                                    |
| MR-14 | Output shall group same-named agents and plural branch/PR resources by repository, show current checkout as observation, and use UUIDs plus exact resource identities for mutation.          |
| MR-15 | Restore, stop, delete, and archive semantics shall remain idempotent per agent across a multi-repository batch.                                                                            |
| MR-16 | Promotion while cwd is in a repository's primary worktree shall retain the MVP/advanced-promotion semantics unchanged.                                                                     |
| MR-17 | An agent-creation flow entered through `/agents` from a directory controller shall require an explicit target repository before it creates durable intent or invokes a repository adapter. |
| MR-18 | Cross-repository delegation shall link globally unique `agentId` and manager-assigned `parentAgentId` values and shall never imply shared Git bases, topology, or resource ownership.       |
| MR-19 | Directory listing shall be able to render durable records and valid per-agent observation caches before external refresh completes.                                                        |
| MR-20 | Cross-repository refresh shall observe Kitty once globally, Worktrunk once per repository, and other sources with bounded concurrency, then merge observations by source timestamp.        |
| MR-21 | Scope membership and destructive eligibility shall use durable records and fresh observations, never cached derived status.                                                                |
| MR-22 | A future background process shall be able to reuse the same observer, cache merge, and UI-update contracts without changing agent semantics.                                               |
| MR-23 | Optional Worktrunk hooks shall request full repository refresh only and shall not write cross-repository event deltas.                                                                     |
| MR-24 | A directory controller shall remain outside the delegation forest; any operator-origin communication authority shall come from its registered local connection or capability, not a controller ID or message-body claim. |
| MR-25 | Cross-repository delegation shall never cascade deletion or archive; every supporting agent remains an independent candidate and relationship edges must be resolved before a parent vanishes. |
| MR-26 | Cross-repository creation shall preserve one-worktree-per-agent cardinality; simultaneous checkout of parallel branches shall use separate related agents.                                    |

## 10. User-facing behavior

### 10.1 Natural-language examples

From `~/src`, where several repositories have registered agents:

```text
Show me all active agents under here.
Restore the stopped agents in api and frontend.
Which agents have failed checks?
Clean up agents whose PRs merged more than seven days ago across these repos.
Create an agent in ./frontend for the accessibility fix.
```

The model translates those requests into typed scope selection and agent IDs.
It does not shell-loop over directories.

### 10.2 `/agents` command namespace

When cwd is outside a Git repository, `/agents` offers directory scope and
shows:

```text
api/
  api-cache       waiting     PR #218 checks passing
  auth-cleanup    stopped     merged 12d ago

frontend/
  a11y-dialog     working     PR #91 review needed
```

Repositories with no registered agents may be omitted unless optional discovery
is explicitly requested. Duplicate agent names are valid and always displayed
with repository context.

The first render uses durable records plus valid cached observations and marks
stale or missing sources. The current Pi process then refreshes selected
repositories with bounded concurrency and updates changed rows when supported
by the UI component. The UI supports narrowing to repositories or agents before
any mutation.

A creation action or creation-focused subcommand outside a repository first
presents or requires an explicit repository selection. Only then does it begin
the same durable provisioning flow used by the MVP. Merely running Pi in a
parent directory never supplies an implicit target repository.

Focused subcommands remain interactive UX routes. For example, a possible
`/agents resume` route resolves the directory scope, groups stopped/restorable
agents by repository, allows multi-selection, and dispatches the selected UUIDs
through the ordinary per-agent restore operation. The command text does not
bypass scope resolution or become mutation authority.

### 10.3 Tool schema

The `agents` tool extends relevant actions with a structured scope:

```ts
type ScopeInput =
  | { kind: "current" }
  | { kind: "current-directory" }
  | { kind: "repository-ids"; ids: string[] };
```

`current-directory` means the canonical current cwd captured by extension code,
not a model-provided path. Repository IDs returned by a prior selection may be
used explicitly.

Human names, repository basenames, and branch names remain search/display
values only. Mutation uses stable agent UUIDs or opaque plan tokens.

## 11. Cross-repository reconciliation

For a resolved scope:

1. Load matching durable agent records once.
1. Load only caches matching each record revision/resource fingerprint.
1. Return or render the repository-grouped cache-first view.
1. Group refresh work by repository common directory.
1. Query Kitty topology once globally and index by agent UUID.
1. Reconcile each repository using one Worktrunk list call.
1. Check Pi-session/resource paths per agent.
1. Query Git/GitHub only for requested status or policy, with bounded
   concurrency.
1. Construct complete observed snapshots, derive status, and merge newer
   source observations into each cache.
1. Return repository-grouped refresh results and independent errors.

One inaccessible or broken repository does not make another repository's local
status unknown. The result explicitly distinguishes:

- repository failure;
- agent/resource failure;
- GitHub-only failure;
- successful observation.

## 12. Batch operation semantics

### 12.1 Read and non-destructive operations

List and inspect may reconcile repositories concurrently within a small
configured limit. Focus is naturally one agent. Multi-agent restore and stop
are sequential initially to expose interactive failures and avoid Kitty races.

Cache-first results always include freshness metadata. A caller that requires
fresh status waits for observation rather than treating the initial cache as
final.

### 12.2 Destructive plan

```ts
type MultiRepoPlan = {
  token: string;
  createdAt: string;
  expiresAt: string;
  scope: {
    kind: "directory" | "repositories";
    root?: string;
    repositoryCommonDirs: string[];
  };
  repositories: Array<{
    commonDir: string;
    primaryWorktree: string;
    candidates: Array<{
      agentId: string;
      recordRevision: string;
      reason: string;
      resourceActions: ResourceAction[];
    }>;
    excluded: Array<{ agentId: string; reason: string }>;
  }>;
};
```

Confirmation covers the displayed plan, but execution remains a sequence of
independent agent reconciliations. The result reports, for every candidate:

```text
completed
skipped-after-revalidation
partially-completed/resumable
failed-with-no-mutation
```

There is no overall “rolled back” status.

### 12.3 Locking

Do not hold several repository locks while waiting on GitHub or Kitty. For each
repository in deterministic order:

1. acquire its repository lock;
1. reacquire the selected agent lock;
1. freshly observe and repeat plan revalidation without cache;
1. execute and journal resource operations;
1. release locks before advancing.

This avoids cross-repository deadlocks and keeps unrelated repositories usable
during a long batch.

## 13. Creating agents from a directory controller

A Pi session outside any repository cannot use MVP promotion because it has no
source repository, primary worktree, branch, or Git state.

The creation flow entered through `/agents` may create a managed agent after
the user selects:

- target repository;
- new initial branch;
- target-repository base revision;
- name.

There is no lifecycle-level assignment prompt or model-selected
`parentAgentId`. Ordinary fresh-agent provisioning from this unmanaged session
creates a top-level agent with `parentAgentId: null`. An authenticated operator
channel may deliver its assignment after registration, but does not make the
controller a parent or resource owner.

An optional later operation could fork the controller's Pi-session history into
a chosen repository agent. That changes continuation semantics and is not part
of this feature.

## 14. Cross-repository supporting agents

Global agent UUIDs and `parentAgentId` make cross-repository delegation
structurally possible without a workspace aggregate. A managed agent in
repository A may spawn a supporting child in repository B when the target is
explicit. An unmanaged root controller may create a top-level agent in any
explicitly selected repository.

Differences from same-repository spawn:

- base revision is resolved in repository B and never defaults to repository
  A's HEAD;
- the child owns exactly one repository B worktree and only its own repository B
  branches, PRs, Pi session, and tab;
- the relationship is delegation provenance/coordination, not Git or resource
  ownership;
- parent deletion/archive never selects the child implicitly; a remaining edge
  blocks disappearance until the child is independently deleted, reparented,
  or detached;
- list views within repository B may show an out-of-scope managed-agent parent
  as a labeled UUID reference rather than silently omitting the relationship;
- no Git ancestry, branch relationship, filesystem sharing, or PR relationship
  is inferred from parentage. The child may intentionally work on a structurally
  sibling branch or PR.

A directory controller never becomes the delegation parent. Agents created
from directory scope are top-level unless a managed agent is the authenticated
creator.

When a child asks its parent to authorize another agent, manager code chooses
between two safe placements: child of the requester when the requester will
manage it, or another child of the authorizing parent for parallel work
coordinated there. The request body cannot name an arbitrary
`parentAgentId`.

## 15. Promotion behavior

Promotion remains repository-specific:

- inside a primary worktree, clean MVP promotion applies;
- inside a dirty or non-default primary worktree, the advanced-promotion
  feature may apply;
- inside a managed worktree, the current Pi session is already associated with
  an agent and is not promoted again;
- outside a repository, promotion refuses and offers creation in an explicitly
  selected repository.

Directory scope affects what the controller can manage; it does not weaken
promotion's repository/worktree preconditions.

## 16. Moved repositories and rebinding

If a primary repository moves, canonical path identity changes. The feature
must report the old binding as unavailable rather than guessing based on a
remote URL or basename.

A later explicit `rebind_repository` operation may:

1. select the old repository identity;
1. select and canonicalize the new primary worktree;
1. prove compatible Git identity and Worktrunk topology;
1. show every affected agent/resource path;
1. update records atomically under a repository lock.

Automatic rebinding is outside this feature. Existing absolute managed
worktree and Pi-session paths may remain valid even when the primary clone
moves, so deletion and repair require careful reconciliation rather than bulk
path substitution.

## 17. Safety and performance

- A directory scope rooted at `/`, a home directory, or another unusually broad
  location requires explicit UI confirmation or configured allowance.
- Canonical path containment, not lexical prefix alone, determines scope.
- Symlinks cannot expand a selected scope silently.
- Destructive commands receive resolved agent resources, never directory-scan
  results or model-generated paths.
- GitHub requests are deduplicated per exact repository/PR identity and
  concurrency limited; current checkout does not select a single implicit PR.
- Cache reads do not spawn subprocesses and may supply the entire first render.
- Worktrunk list calls are one per reconciled repository, not one per agent.
- Kitty topology is fetched once per cross-repository operation.
- Refresh requests for the same repository may be coalesced; an older
  observation can never replace a newer cache entry for the same source.
- Optional hooks request full repository refresh and may be dropped or
  duplicated without changing correctness.
- Large results support pagination/filtering before the model receives full
  resource details.
- A partial batch outcome is persisted and resumable per agent.

## 18. Configuration

```ts
export const agentsConfig = {
  // Existing MVP configuration...
  multiRepository: {
    enabled: true,
    registryFirst: true,
    maxRepositoryConcurrency: 4,
    maxGithubConcurrency: 4,
    cacheFirst: true,
    backgroundRefresh: false,
    broadScopeRootsRequiringConfirmation: ["/", "~"],
    discovery: {
      enabled: false,
      maxDepth: 3,
      followSymlinks: false,
      crossFilesystems: false,
      exclude: ["node_modules", ".cache"],
    },
  },
};
```

The initial implementation should leave optional discovery disabled. Existing
agent management works entirely from durable records and their disposable
observation caches. `backgroundRefresh: false` means refresh work runs only in
the current Pi process; a future updater can enable the same cache contract.

## 19. Failure handling

- Failure to resolve cwd produces no scope and no mutation.
- A missing repository is reported with every affected agent; it is not dropped
  from the registry.
- A missing, corrupt, or mismatched observation cache renders as unknown and is
  rebuilt; it does not hide the durable agent.
- A Worktrunk failure blocks only that repository's topology-dependent
  operations.
- Kitty failure blocks live-tab mutations but does not erase registry state.
- GitHub failure excludes agents from GitHub-dependent cleanup while allowing
  local status.
- A stale plan skips or stops at the affected agent according to the confirmed
  plan policy and records exact outcomes.
- Process interruption leaves per-agent operation journals that ordinary MVP
  recovery can resume.

## 20. Suggested implementation order

1. Refactor MVP current-repository selection into an internal
   `ManagementScope` resolver while exposing only repository scope.
1. Add registry path-containment queries and repository deduplication tests.
1. Add cache-first read-only directory scope grouped by repository.
1. Add repository-grouped refresh and per-source cache merging.
1. Add multi-repository inspect and GitHub status with bounded concurrency.
1. Add explicit target-repository fresh-agent creation.
1. Add sequential restore/stop across selected repositories.
1. Add multi-repository delete/cleanup plans using existing per-agent execution.
1. Add cross-repository supporting-agent creation with manager-derived
   `parentAgentId`.
1. Consider optional bounded repository discovery only after registry-first
   workflows are satisfactory.

## 21. Acceptance criteria

1. Running Pi above three repositories lists registered agents from all three,
   grouped correctly.
1. A Worktrunk worktree beneath the directory is not displayed as another
   repository.
1. A managed worktree outside the directory is still included when its primary
   repository is beneath the directory.
1. Duplicate agent, branch, and PR display names in different repositories
   remain unambiguous by UUID, exact resource identity, and repository context.
1. Directory listing requires no filesystem scan when all agents are already
   registered.
1. Restore and stop across repositories preserve ordinary per-agent
   idempotence.
1. A cleanup plan for old merged PRs lists exact resource effects grouped by
   repository and performs no mutation before confirmation.
1. A stale or failed agent in one repository does not misreport successful
   agents in another.
1. Interruption halfway through cleanup yields completed and resumable
   per-agent outcomes, not an atomicity claim.
1. A parent-directory Pi session remains unmanaged, has no controller record,
   and is absent from `/agents`.
1. Creating from the directory controller requires an explicit target
   repository and produces `parentAgentId: null`.
1. Cross-repository supporting-agent creation resolves its base in the child's
   repository, gives the child exactly one worktree, and creates no shared
   resource ownership or inferred Git relationship.
1. Selecting a cross-repository parent for cleanup never selects its child; an
   unresolved `parentAgentId` edge blocks disappearance until explicit delete,
   reparent, or detach.
1. Moving a repository results in an explicit broken binding rather than
   remote-name guessing.
1. No operation introduces a multi-repository workspace or daemon.
1. A directory containing many cached agents renders before adapter refreshes
   complete, with visible freshness metadata.
1. A stale cache cannot add/remove scope members or make an agent eligible for
   cleanup.
1. New observations update only affected source timestamps and agent rows.

## 22. Testing implications

Multi-repository behavior follows the shared
[testing strategy](agents-testing-strategy.md):

- scope resolution, path containment, repository deduplication, cache merging,
  grouping, and batch-plan construction are pure Vitest tests;
- fake adapters assert one Kitty observation per refresh and one Worktrunk
  observation per repository;
- controlled promises test bounded concurrency, cache-first rendering, and
  out-of-order completion without sleeps;
- destructive batch tests provide fresh scripted observations and verify that
  cached safety state is ignored;
- no automated test scans a real repository tree, starts Kitty, contacts
  GitHub, or runs Worktrunk.

## 23. References

- [MVP design](agents-design.md)
- [Testing strategy](agents-testing-strategy.md)
- [Archive lifecycle](agents-archive.md)
- [Delegation and communication security](agents-delegation-communication.md)
- [Dirty/non-default promotion](agents-transactional-promotion.md)
- [Git worktrees](https://git-scm.com/docs/git-worktree)
- [Worktrunk worktree listing](https://worktrunk.dev/list/)
- [Kitty remote control](https://sw.kovidgoyal.net/kitty/remote-control/)
