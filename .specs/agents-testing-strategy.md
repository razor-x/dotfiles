# Agents: Testing Strategy

Status: companion engineering specification\
Applies to: MVP and all deferred feature specifications\
Implementation home: `razor-x/dotfiles`\
Test framework: Vitest

## 1. Purpose

The `agents` extension coordinates several external systems whose real behavior is
expensive, stateful, interactive, authenticated, or visually obvious:

- Pi sessions and extension UI;
- Worktrunk and Git worktrees;
- Kitty tabs and remote control;
- Git, current checkout, and plural local/remote branches;
- plural GitHub PRs and checks;
- delegation identities and any authenticated inter-agent transport.

The automated suite should not recreate those systems. Its highest-value job is
to prove that the extension makes the correct decisions and updates durable and
cached state correctly for every external observation and effect result.

The central testing strategy is:

> Build a functional domain core, exercise orchestration through typed fake
> adapters, test adapters as translation contracts, use the real filesystem
> only for narrow persistence/restart contracts, and keep live-system behavior
> in a concise manual acceptance suite.

This document is normative for:

- [MVP design](agents-design.md);
- [Kitty remote-control security boundary](agents-kitty-security.md);
- [archive lifecycle](agents-archive.md);
- [dirty/non-default promotion](agents-transactional-promotion.md);
- [multi-repository control](agents-multi-repo-control.md);
- [delegation and communication security](agents-delegation-communication.md).

## 2. Settled testing decisions

1. **Use Vitest.** Follow Pi's existing TypeScript/Vitest conventions where
   practical: `.test.ts` files, explicit Vitest imports, Node execution, and a
   non-watch `vitest --run` CI command.
1. **Functional core, imperative shell.** Reconciliation, planning, cache
   merging, eligibility, resource ordering, and operation transitions are pure
   functions over typed values.
1. **Fake typed adapters in application tests.** Tests supply observations and
   effect outcomes directly rather than mocking subprocess implementation
   details.
1. **Test adapter translations separately.** Captured output fixtures and a
   fake command runner verify parsing, normalization, and exact safe argument
   arrays without starting external programs.
1. **No live external systems in the normal suite.** Automated tests do not
   create PRs, control Kitty, create/remove real Worktrunk worktrees, or run an
   interactive Pi process.
1. **Use in-memory persistence by default.** Domain and orchestration tests do
   not touch disk.
1. **Inject persistence failures.** A fault-injecting store simulates errors and
   uncertain commit outcomes at exact operation boundaries.
1. **Use real temporary directories narrowly.** Durable-store contracts,
   malformed JSON, atomic replacement behavior, archive publication, and
   restart recovery use isolated temporary roots.
1. **Separate durable and observed state.** Durable agent records receive
   stronger revision/recovery tests. Observation caches are tested as
   disposable, stale, mergeable hints.
1. **Observation, not hook event replay.** Worktrunk hooks merely request a
   complete refresh. Tests cover duplicate/coalesced refresh requests rather
   than asynchronous semantic hook streams.
1. **Minimal Pi UI automation.** Verify registration, schema, delegation, and
   pure formatting. Test actual interaction and rendering manually.
1. **No timing sleeps.** Fake clocks, deterministic IDs, controlled promises,
   and explicit barriers make time and concurrency reproducible.

## 3. What the automated suite is proving

The suite is primarily a specification for state transitions:

```ts
reconcile(
  agentRecord: ManagedAgentRecord,
  observed: ObservedAgentSnapshot,
): DerivedAgentState;

plan(
  command: AgentCommand,
  agentRecord: ManagedAgentRecord,
  derived: DerivedAgentState,
): Decision;

advance(
  operation: OperationState,
  result: EffectResult,
): OperationTransition;

mergeObservationCache(
  current: AgentObservationCache | null,
  incoming: SourceObservations,
  agentRecord: ManagedAgentRecord,
): AgentObservationCache;
```

Given explicit values, tests prove:

- the derived status is correct;
- the command is accepted or refused for the correct reason;
- the exact typed effects are planned in safe dependency order;
- a completed, failed, duplicated, absent, or uncertain effect advances the
  operation correctly;
- durable state and disposable cache state change independently;
- interrupted work is resumable without treating ambiguity as success.

The suite is not trying to prove that GitHub, Kitty, Git, Pi, or Worktrunk work
according to their own documentation.

## 4. Architecture required for testability

### 4.1 Functional domain core

Domain modules receive plain immutable values and return plain values. They do
not import:

- Pi extension APIs;
- `node:child_process`;
- `node:fs`;
- `Date.now()`;
- UUID/random generators;
- Kitty, Git, Worktrunk, or `gh` clients;
- module-global mutable state.

Suggested pure modules:

```text
domain/
  reconcile.ts
  observation-cache.ts
  eligibility.ts
  plans.ts
  resource-order.ts
  operation-transition.ts
  delegation.ts
  communication-authorization.ts
  scope.ts
  schemas.ts
```

### 4.2 Imperative application shell

Application services coordinate ports:

```ts
type AgentsPorts = {
  agents: AgentStore;
  observations: ObservationCacheStore;
  operations: OperationStore;
  plans: PlanStore;
  locks: LockManager;

  pi: PiSessionAdapter;
  worktrunk: WorktrunkAdapter;
  kitty: KittyAdapter;
  git: GitAdapter;
  github: GitHubAdapter;

  clock: Clock;
  ids: IdGenerator;
};
```

The shell:

1. loads durable records;
1. obtains typed observations from adapters;
1. calls pure domain functions;
1. persists intent before external effects when required;
1. executes one typed effect;
1. feeds its result back into the operation reducer;
1. persists the next state;
1. repeats until complete, refused, or recovery-required.

Tests can stop after any step and construct a new service instance over the
same fake or temporary store.

### 4.3 Pi extension wiring

The default extension export should be thin enough to test separately:

```ts
export function registerAgents(
  pi: ExtensionAPI,
  services: AgentsServices,
): void;

export default function extension(pi: ExtensionAPI): void {
  registerAgents(pi, createProductionServices());
}
```

Wiring tests pass a fake `ExtensionAPI`, capture registered tools/commands/event
handlers, invoke them with fake contexts, and assert delegation to application
services.

## 5. Normative testing requirements

| ID    | Requirement                                                                                                                                                                                                                         |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| TS-01 | The project shall use Vitest as its automated test runner.                                                                                                                                                                          |
| TS-02 | The default test command shall run deterministically without network access, external credentials, Kitty remote control, Worktrunk mutation, or an interactive Pi process.                                                          |
| TS-03 | Reconciliation, planning, eligibility, resource ordering, cache merging, and operation transitions shall be testable as pure functions.                                                                                             |
| TS-04 | Application orchestration shall depend on typed adapters supplied by dependency injection.                                                                                                                                          |
| TS-05 | Normal orchestration tests shall use scripted fake adapters rather than module-level mocks of subprocess implementations.                                                                                                           |
| TS-06 | Adapter contract tests shall verify captured-output parsing and exact argument arrays without executing the real program.                                                                                                           |
| TS-07 | Tests shall verify that force flags, shell interpolation, title-based identity, and unvalidated model paths cannot enter destructive adapter calls.                                                                                 |
| TS-08 | Durable agent, plan, and operation stores shall have a shared contract exercised by both in-memory and filesystem-backed implementations where applicable.                                                                          |
| TS-09 | Filesystem-backed tests shall use a unique injected temporary state root and shall never read or write the user's real home, XDG state, Pi sessions, Kitty config, Git config, or repositories.                                     |
| TS-10 | A fault-injecting store shall simulate failure before commit, after durable commit but before acknowledgement, and on stale expected revision.                                                                                      |
| TS-11 | Restart tests shall create a fresh service/store instance rather than reuse process-local state.                                                                                                                                    |
| TS-12 | Observation-cache tests shall prove revision/fingerprint invalidation, per-source freshness merging, corruption tolerance, and safe absence.                                                                                        |
| TS-13 | Destructive-operation tests shall prove that cached observations never satisfy fresh safety checks.                                                                                                                                 |
| TS-14 | Concurrency tests shall use controlled promises/barriers and fake clocks rather than sleeps or scheduler timing assumptions.                                                                                                        |
| TS-15 | Duplicate or concurrent refresh requests shall be tested as complete observations, not ordered Worktrunk semantic events.                                                                                                           |
| TS-16 | Pi UI tests shall be limited to wiring, delegation, schemas, and pure formatting unless a stable Pi-provided UI harness makes additional behavior cheap.                                                                            |
| TS-17 | Live-system validation shall be documented as a manual acceptance checklist separate from `vitest --run`.                                                                                                                           |
| TS-18 | Every normative destructive safety requirement shall map to at least one named automated test.                                                                                                                                      |
| TS-19 | Test fixtures shall contain no credentials, private repository content, Pi-session content, or user-specific absolute paths.                                                                                                        |
| TS-20 | Tests shall assert externally meaningful decisions, effects, and state rather than incidental internal call structure.                                                                                                              |
| TS-21 | Every implementation increment shall pair one runnable Pi acceptance demonstration with automated tests for the newly reachable state transitions and adapter boundaries.                                                           |
| TS-22 | The first `/agents` creation-flow increment shall prove that it writes an empty revision-zero `provisioning` record and invokes no Worktrunk, Pi-session, Kitty, observation-cache, or GitHub adapter/store.                        |
| TS-23 | `/agents` subcommand tests shall treat verbs as UI routes: they shall verify scope/eligibility filtering, picker delegation, UUID resolution, cancellation, and unknown-subcommand help without duplicating domain-operation tests. |
| TS-24 | Multi-select command-flow tests shall prove stable selection ordering, independent per-agent outcomes, and no effect for an empty or canceled selection.                                                                            |
| TS-25 | Cardinality tests shall prove one canonical worktree, one-or-more explicit local branches, plural remote branch/PR resources, and exactly one observed current checkout per active agent.                                                                  |
| TS-26 | Branch-switch tests shall prove clean/no-operation/topology preflight, exact argument arrays, unchanged agent/worktree identity, and post-switch observation.                                                                            |
| TS-27 | Discovery, inspection, PR-head references, and checkout shall be tested not to confer branch/PR ownership or association.                                                                                                                 |
| TS-28 | Delegation tests shall prove that parent selection never adds a child to delete/archive candidates and that dangling edges require independent delete, reparent, or detach.                                                              |
| TS-29 | Communication authorization tests shall derive sender from a registered connection/capability, reject sender fields in bodies, allow only ancestor/descendant routes, and deny unrelated trees and siblings by default.                 |
| TS-30 | Identity tests shall prove models cannot select or mutate `parentAgentId`, and that reparent/detach updates affected parent links and rotates capabilities atomically.                                                                                     |
| TS-31 | Root-controller tests shall prove the controller remains unmanaged with no controller record or stable controller ID, while any operator ingress is bound to its registered local connection/capability.                                                        |

## 6. Test layers

| Layer                     | Uses                                     | Does not use                | Primary value                                |
| ------------------------- | ---------------------------------------- | --------------------------- | -------------------------------------------- |
| Pure domain               | Plain values                             | Adapters, filesystem, Pi UI | Decision tables and state transitions        |
| Application orchestration | Fake adapters, in-memory/fault store     | Real subprocesses/network   | Sequencing, journaling, recovery             |
| Adapter contract          | Fake command runner, checked-in fixtures | Real external program       | Parsing and safe command construction        |
| Persistence contract      | Real temporary directory                 | User state/external tools   | Round-trip, revisions, interruption recovery |
| Extension wiring          | Fake Pi API/context                      | Interactive terminal UI     | Registration and delegation                  |
| Manual acceptance         | Disposable real resources                | CI automation               | End-to-end usability and integration         |

The test pyramid should be dominated by pure domain and orchestration tests.
Adapter, persistence, and wiring suites remain small.

## 7. Pure domain tests

### 7.1 Reconciliation matrix

Use table-driven `it.each` cases for combinations such as:

- registered worktree present/missing/primary;
- Pi session present/missing;
- zero/one/multiple Kitty tabs;
- working/waiting lifecycle signal;
- Git clean/dirty/conflicted/unobservable;
- zero/one/many explicit PRs with independently open/closed/merged/unobservable
  states;
- zero/one/many branch resources, one current checkout, and mismatched or
  multiply checked-out topology;
- durable record revision matching/mismatching cache;
- source observations fresh/stale/error.

Each case asserts the complete `DerivedAgentState`, including health, activity,
restorability, freshness, and refusal reasons.

### 7.2 Planning

Planning tests assert exact typed decisions:

- the first `/agents` creation action creates durable intent with `revision: 0`,
  `lifecycle: "provisioning"`, and `resources: []`;
- a provisioning operation advances only through the phases implemented or
  successfully verified and never reports an incomplete agent as active;
- clean/default promotion accepted;
- dirty/default promotion refused by MVP and accepted by the advanced strategy;
- restore becomes focus when one tab already exists;
- duplicate tabs refuse;
- stop is idempotent when no tab exists;
- explicit delete includes exact independent actions/dispositions for every
  PR and branch resource, with worktree removal ordered last;
- associated resources require adopt-on-confirmation;
- old-merged cleanup uses the injected clock and fresh `mergedAt`;
- parent deletion never selects descendants and refuses until each child edge
  is independently deleted, reparented, or detached;
- archive retains only Pi session and archive record;
- multi-repository plans group agents by canonical repository identity.

Prefer explicit equality over broad snapshots:

```ts
expect(decision).toEqual({
  kind: "refused",
  code: "worktree-dirty",
  message: expect.any(String),
});
```

### 7.3 Operation reducers

For every operation phase, test results including:

- succeeded;
- already absent/closed under a known retry;
- refused before mutation;
- failed with known no-effect;
- failed after possible effect;
- malformed adapter result;
- stale durable revision;
- process restart between effect and acknowledgement.

The reducer must distinguish “definitely did not happen” from “may have
happened.” An uncertain external effect produces re-observation or an
idempotent retry, never an assumed rollback.

### 7.4 Delegation and scope

Pure tests cover:

- independent child selection and child-before-parent ordering only when both
  were separately selected;
- parent blocking without cascade;
- explicit reparenting and detachment;
- manager-assigned `parentAgentId` changes and capability-rotation decisions;
- cross-repository managed-agent parent IDs;
- ancestor/descendant authorization, sibling denial, and unrelated-tree denial;
- canonical path containment;
- Worktrunk common-dir deduplication;
- moved/broken repository identity;
- broad directory-scope confirmation.

## 8. Observation-cache tests

The cache is separately testable because it contains no ownership truth.

### 8.1 Validity

Test that a cache is ignored when:

- absent;
- malformed;
- unknown schema;
- wrong agent ID;
- older or newer incompatible agent revision;
- resource fingerprint differs.

The durable agent remains listable with unknown observations.

### 8.2 Per-source merge

Test source-by-source timestamps:

- a newer Kitty observation replaces Kitty only;
- an older GitHub result cannot replace newer GitHub state;
- a GitHub error does not erase fresh Kitty/Worktrunk state;
- equal timestamps resolve deterministically;
- derived summary is recomputed from merged sources;
- resource revision change invalidates the entire prior cache.

### 8.3 Cache-first refresh

With fake observers and controlled promises, prove:

1. durable records and cached rows are available before observation promises
   resolve;
1. stale/unknown sources are labeled correctly;
1. refresh results update only affected rows/sources;
1. out-of-order refresh completion cannot regress newer source state;
1. cache-write failure leaves the refreshed in-memory/UI result usable;
1. a later refresh reconstructs a missing cache.

### 8.4 Destructive cache bypass

For every destructive workflow, include at least one test where cache says
“safe” but fresh observation says unsafe or fails. The operation must refuse.

Examples:

- cache says stopped; fresh Kitty sees a tab;
- cache says clean; fresh Git sees changes;
- cache says merged; fresh GitHub says open;
- cache says worktree exists; Worktrunk cannot resolve it;
- cache says no descendants; durable registry contains one.

## 9. Scripted adapter fakes

Application tests use fakes at domain-level interfaces:

```ts
class ScriptedWorktrunkAdapter implements WorktrunkAdapter {
  readonly calls: WorktrunkCall[] = [];

  constructor(private readonly script: WorktrunkStep[]) {}

  async create(input: CreateWorktreeInput): Promise<WorktreeResult> {
    this.calls.push({ kind: "create", input });
    return takeExpectedStep(this.script, "create", input);
  }
}
```

Each fake:

- records typed calls;
- consumes an explicit result/error script;
- fails immediately on an unexpected call or order;
- supports deferred results for concurrency tests;
- contains no knowledge of subprocess arguments.

Provide reusable fake factories with safe defaults:

```ts
const harness = createHarness({
  agent: agentBuilder().stopped().build(),
  observed: observedBuilder().healthy().clean().build(),
  clock: "2026-08-16T12:00:00Z",
});
```

Tests override only facts relevant to the case. Builders must produce valid
domain objects by default so a test cannot accidentally depend on malformed
irrelevant data.

## 10. Adapter contract tests

Typed adapter fakes prove orchestration. Contract tests prove the production
adapter translates external protocols safely.

### 10.1 Command runner boundary

All subprocess adapters depend on one injectable runner:

```ts
interface CommandRunner {
  run(command: string, args: readonly string[], options: RunOptions): Promise<RunResult>;
}
```

The fake runner captures `command`, `args`, cwd, environment allowlist, stdin,
exit status, stdout, and stderr. It never invokes a shell.

### 10.2 Worktrunk

Test:

- exact structured-output arguments;
- canonical primary/current worktree parsing;
- explicit schema mismatch refusal;
- create/remove success and partial outcomes;
- no `--force`, `--force-delete`, or unvalidated `--yes` path;
- exact reconciled worktree targeting;
- hook failure surfaced as part of the Worktrunk effect;
- post-command full observation requested rather than hook-delta mutation.

### 10.3 Kitty

Test:

- `kitten @ ls` fixture normalization;
- exact `pi_managed_agent=<uuid>` matching;
- zero/one/duplicate tab detection;
- safe launch/focus/close/title/user-variable arguments;
- escaping of restoration-template values;
- no model-provided match expression or title-only identity.

Actual tab rendering, focus behavior, and interactive prompts remain manual.

### 10.4 Git and GitHub

Test:

- porcelain/current-checkout/plural-branch/topology fixture parsing;
- dirty, conflict, operation-in-progress, unpushed, detached, and target-checked-
  out-elsewhere states;
- exact `git switch -- <validated-branch>` argument construction with no shell,
  force, guess, or model-supplied arbitrary ref;
- `gh` JSON normalization for zero/one/many exact PR resources across
  open/draft/closed/merged/check/review states;
- authentication/network/malformed-output errors;
- exact repository and PR-number targeting;
- PR close terminology and command construction;
- no PR-title parsing and no shell interpolation.

No adapter contract test contacts a remote or creates a Git repository.

### 10.5 Pi session adapter

Use a small fake Pi-session adapter boundary to test:

- source Pi-session persistence requirement;
- `forkFrom` target cwd/Pi-session directory;
- `switchSession` ordering;
- custom agent-ID metadata;
- source Pi-session retention;
- failure before/after destination Pi-session creation.

Do not automate a real interactive Pi process in the normal suite.

## 11. State-store strategy

### 11.1 Production rule

All durable agent, operation, plan, and archive state flows through explicit
store interfaces. Production code does not call `writeFile` ad hoc from domain
or orchestration modules.

Observation caches use a separate store because cache corruption or loss must
not affect ownership state.

### 11.2 In-memory store

Most tests use an in-memory implementation that preserves important production
semantics:

- schema validation;
- immutable returned values;
- expected-revision compare-and-set;
- unique-create behavior;
- deterministic listing order;
- not-found and stale-revision errors.

It should not silently accept behavior that the filesystem store would reject.

### 11.3 Fault-injecting store

Wrap any store with a scripted failure layer:

```ts
failNext({
  store: "operations",
  method: "put",
  phase: "after-commit-before-return",
  error: new UnknownCommitOutcome(),
});
```

Required fault points:

- before temporary write;
- after temporary write, before rename;
- after rename/durable commit, before caller acknowledgement;
- expected-revision mismatch;
- malformed existing JSON;
- read failure;
- delete failure;
- cache write failure.

An uncertain durable commit is resolved by rereading the record/operation ID,
not by blindly repeating a non-idempotent transition.

### 11.4 Filesystem-store contract

Use a fresh `mkdtemp` root for each test or suite. Inject it directly; never
derive it from the real `HOME`, `XDG_STATE_HOME`, cwd, Pi config, or dotfiles.

Narrow real-filesystem cases:

- empty provisioning-record creation and reopen after a fresh process/store
  instance;
- create/read/update/delete round-trip for each durable record kind;
- expected-revision rejection;
- valid old-or-new JSON after replacement;
- restrictive file/directory permissions where portable;
- malformed/truncated record refusal;
- unknown schema read-only behavior;
- leftover temporary sibling ignored/reported and safely cleanable;
- independent agent files do not overwrite each other;
- reconstructing a fresh store instance sees committed state;
- archive Pi-session copy/checksum/publication;
- observation-cache corruption degrades to cache miss.

These tests validate the store algorithm and recovery behavior. They do not
claim to simulate arbitrary kernel or power-loss behavior. Full filesystem and
directory `fsync` durability is outside the MVP unless explicitly implemented.

## 12. Restart and interruption tests

Every multi-phase operation should support a shared table-driven crash harness:

```ts
for (const phase of operationPhases) {
  it(`recovers after interruption at ${phase}`, async () => {
    const stores = createPersistentTestStores();
    await runUntilPhase(stores, phase);

    const restarted = createService({ stores: stores.reopen() });
    const recovery = await restarted.inspectInterruptedOperations();

    expect(recovery).toEqual(expectedRecoveryAt(phase));
  });
}
```

Cover:

- promotion provisioning;
- supporting-agent provisioning and manager-assigned relationship registration;
- branch association/switch around effect/observation uncertainty;
- stop/restore around tab uncertainty;
- resource-by-resource deletion;
- archive snapshot/copy/teardown/publication;
- transactional promotion capture/apply/activation;
- multi-repository batch progress.

The restart creates new services, fake adapters, and clocks while retaining
only the chosen persisted state.

## 13. Concurrency and refresh tests

Concurrency is tested deterministically at the domain/application boundary.

### 13.1 Durable writers

Test two writers using the same expected revision:

- exactly one durable update succeeds;
- the stale writer receives `StaleRevision`;
- it reloads/reconciles rather than overwriting;
- both resulting JSON documents are individually valid.

Atomic rename prevents partial JSON; revision control prevents valid
last-writer-wins state loss.

### 13.2 Repository operations

Use a fake lock manager and controlled adapter promises to prove:

- two topology mutations in one repository serialize or one refuses;
- mutations in different repositories may proceed within configured bounds;
- no repository lock is held while awaiting unrelated GitHub observations;
- a stale plan is revalidated after acquiring the lock;
- an effect may succeed while its acknowledgement is lost, followed by safe
  re-observation/idempotent continuation.

### 13.3 Refreshes and hooks

Hooks are tested only as refresh triggers:

- one hook requests one complete repository refresh;
- duplicate requests may coalesce;
- a missing or failed hook does not affect correctness;
- an older completed refresh cannot replace newer per-source cache entries;
- hook handling does not patch durable agent records;
- extension-initiated Worktrunk operations refresh after the adapter returns
  regardless of hooks.

No test needs an asynchronous event queue, daemon, or semantic Worktrunk hook
ordering model.

## 14. Pi UI and extension tests

### 14.1 Automated wiring

The fake Pi API captures:

- registered `agents` tool and action schema;
- `/agents` command registration, no-argument overview dispatch, recognized
  subcommand routing, and unknown-subcommand help;
- picker eligibility, cancellation, single-select, and multi-select mapping to
  stable agent UUIDs;
- an illustrative resume route filtering to stopped/restorable agents and
  delegating each selected UUID to the restore service;
- lifecycle event subscriptions;
- handler delegation and normalized errors;
- cached-versus-fresh result metadata;
- correct service calls for selection results.

Pure formatter tests may verify row labels, repository grouping, status icons,
freshness indicators, destructive plan text, and ambiguous-name display.

### 14.2 What not to automate initially

Do not build a synthetic terminal renderer merely to test:

- whether Kitty visually focuses a tab;
- exact picker keyboard interaction;
- incremental terminal redraw behavior;
- terminal dimensions/colors;
- whether a user perceives the cache-first refresh as smooth.

Those are obvious during manual use and expensive to stabilize. If Pi later
provides a small official extension/UI harness that makes them cheap, adopt it
without changing the domain tests.

## 15. Feature scenario ownership

### 15.1 MVP

Automate:

- empty provisioning-intent creation and no-effect adapter assertions;
- durable restart/list behavior before any resource exists;
- reconciliation matrix;
- clean promotion decisions and phase transitions;
- supporting-agent provisioning without assignment delivery;
- stop/restore/focus idempotence;
- plural branch/PR normalization and per-resource ownership/adoption;
- safe sequential branch switching with unchanged worktree identity;
- explicit delete and old-merged cleanup;
- resource ordering, interruption, and recovery;
- cache-first list and destructive cache bypass.

### 15.2 Archive

Automate:

- eligibility and commit reachability;
- immutable snapshot construction;
- retained resource set;
- Pi-session checksum/copy publication;
- non-cascading child selection, reparenting, and detachment;
- teardown and archive-cleanup interruption;
- active cache removal and non-retention.

### 15.3 Transactional promotion

Automate:

- manifest hashing/comparison with synthetic bytes;
- supported/refused source matrices;
- exact phase transitions;
- partial/uncertain stash effect outcomes;
- target verification mismatch;
- concurrency invalidation;
- post-activation resource-fingerprint/cache invalidation.

The suite does not need a real Git stash to prove the orchestration. The Git
adapter contract proves command construction and fixture parsing.

### 15.4 Multi-repository control

Automate:

- scope resolution and common-dir deduplication;
- cache-first grouped rendering;
- bounded refresh scheduling;
- one Worktrunk observation per repository and one Kitty observation globally;
- per-repository errors and partial batch outcomes;
- cross-repository managed-agent delegation and top-level controller-created
  agents;
- moved repository refusal;
- fresh destructive revalidation independent of cache.

### 15.5 Delegation and communication security

Automate:

- manager-only `parentAgentId` assignment and mutation;
- authenticated-connection/capability sender derivation;
- rejection of sender claims and unknown envelope fields;
- ancestor/descendant allow, sibling deny, and unrelated-tree deny matrices;
- an unmanaged root controller with no controller identity, plus separately
  authorized operator-origin delivery;
- requester-managed versus authorizing-parent-managed supporting-agent
  placement;
- reparent/detach subtree updates and capability rotation;
- replay, stale capability, disconnected principal, forged UUID/name/path, and
  broker-address knowledge cases;
- delivery into a fake `pi.sendUserMessage` sink only after authorization.

The normal suite uses an in-memory transport and fake registered connections.
It never opens a real cross-agent socket or relies on prompts for authorization.

## 16. Manual acceptance suite

Manual acceptance uses disposable repositories, branches, PRs, and Kitty tabs.
It is run during implementation increments or after changing an adapter, not on
every edit.

### 16.1 MVP checklist

1. Load the extension in Pi, run `/agents`, enter the available creation flow,
   inspect the reported JSON file, and verify it contains a revision-zero
   `provisioning` record with `resources: []`.
1. Verify that the first increment created no branch, worktree, Pi-session
   fork, Kitty mutation, observation cache, or GitHub request.
1. Restart Pi, open `/agents`, and verify the empty provisioning record is
   loaded from disk.
1. After the Worktrunk increment, enter the same `/agents` creation flow and
   verify its worktree and branch resources are recorded while the current Pi
   cwd remains unchanged.
1. After clean promotion is complete, confirm the same Kitty tab continues
   with the new cwd and Pi session.
1. Confirm Worktrunk and Kitty activity markers update while working/waiting.
1. Spawn, stop, focus, and restore a supporting agent; verify manager-assigned
   `parentAgentId` and no lifecycle-delivered assignment prompt.
1. Associate two branches, switch between them sequentially, and verify current
   checkout changes while agent UUID and canonical worktree remain fixed.
1. Verify a dirty worktree and a target checked out elsewhere each refuse
   switching before mutation.
1. Stop two disposable agents, enter a configured resume/restore subcommand,
   verify its picker excludes ineligible agents, select both, and inspect the
   independent per-agent outcomes.
1. Restart Kitty and restore the exact Pi session through the configured
   restoration recipe.
1. Observe two real PRs and verify independently normalized status.
1. In a disposable repository, confirm an explicit delete plan resolves every
   selected branch/PR independently, closes only confirmed open PRs, and removes
   the worktree last.
1. Verify parent deletion does not select a child and remains blocked until the
   child is independently deleted, reparented, or detached.
1. Confirm a failed or refused Worktrunk hook is surfaced and subsequent full
   observation reconstructs status.
1. Confirm cache-first `/agents` display is visibly replaced by fresh status.

### 16.2 Deferred features

- Archive a disposable merged agent and inspect the retained Pi session and
  snapshot.
- Promote staged, unstaged, and untracked changes and compare target state.
- Run Pi above several disposable repositories and exercise grouped list,
  refresh, restore, cross-repository supporting-agent creation, and cleanup
  planning.
- With disposable sandbox profiles, verify ancestor/descendant communication,
  sibling denial, unrelated-tree denial, and root-controller communication
  without managed resources.

Manual steps must identify disposable targets explicitly. They never run
against the primary dotfiles worktree or valuable branches by default.

## 17. Vitest configuration

Suggested minimal configuration:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "node",
    include: ["<agents-root>/test/**/*.test.ts"],
    clearMocks: true,
    restoreMocks: true,
  },
});
```

Recommended commands:

```json
{
  "scripts": {
    "test": "vitest --run",
    "test:watch": "vitest",
    "test:coverage": "vitest --run --coverage"
  }
}
```

Use explicit imports:

```ts
import { describe, expect, it } from "vitest";
```

Prefer an injected `FakeClock` to globally faking timers. Use Vitest fake timers
only for code whose contract genuinely is timer scheduling.

## 18. Suggested test layout

```text
<pi-extension-root>/local/agents/
  src/
    domain/
    operations/
    adapters/
    stores/
    ui/
    index.ts
  test/
    domain/
      reconcile.test.ts
      observation-cache.test.ts
      plans.test.ts
      operation-transition.test.ts
      delegation.test.ts
      communication-authorization.test.ts
      branch-cardinality.test.ts
      scope.test.ts
    operations/
      promote.test.ts
      spawn.test.ts
      associate-switch-branch.test.ts
      restore-stop.test.ts
      delete.test.ts
      cleanup.test.ts
      archive.test.ts
      transactional-promotion.test.ts
      multi-repo.test.ts
      communication.test.ts
    adapters/
      worktrunk.test.ts
      kitty.test.ts
      git.test.ts
      github.test.ts
      pi-session.test.ts
    stores/
      contract.ts
      memory-store.test.ts
      file-store.test.ts
      fault-store.test.ts
      restart.test.ts
    wiring/
      extension.test.ts
      commands.test.ts
      tools.test.ts
    fixtures/
      worktrunk/
      kitty/
      git/
      github/
    support/
      builders.ts
      harness.ts
      deferred.ts
      fake-clock.ts
      fake-ids.ts
      scripted-adapters.ts
```

The implementation may begin with fewer files. Preserve the boundaries rather
than the exact directory count.

## 19. Fixtures and builders

### 19.1 External fixtures

Fixtures are small, checked-in examples of structured outputs. Each fixture:

- identifies the producing tool/version or schema when known;
- removes credentials and user paths;
- includes only the fields needed for that contract plus representative
  unknown fields;
- has a test for malformed or unsupported schema;
- is updated deliberately when an adapter contract changes.

Do not record entire real Pi sessions or arbitrary repository output.

### 19.2 Domain builders

Builders produce valid defaults and explicit overrides:

```ts
const agent = agentBuilder()
  .named("api-cache")
  .withParentAgentId(parentAgentId)
  .withCanonicalWorktree("/repos/api/.worktrees/api-cache")
  .withBranches(["api-cache", "api-cache-followup"])
  .stopped()
  .build();

const observed = observedBuilder(agent)
  .worktree({ exists: true, clean: false })
  .kitty({ matchingTabs: 0 })
  .build();
```

Avoid giant shared fixtures whose unrelated fields obscure why a test passes.

## 20. Assertions and test style

Prefer assertions on:

- domain result/error codes;
- exact resource actions;
- durable record revisions;
- operation phases and completed actions;
- adapter argument arrays at the adapter-contract layer;
- cache source timestamps and invalidation;
- externally visible text only where it is a stable user contract.

Avoid assertions on:

- private helper call counts;
- internal array order without domain meaning;
- full UI snapshots;
- incidental error stack strings;
- real wall-clock durations;
- subprocess implementation details in domain tests.

Every regression test should first state the externally meaningful failure it
prevents.

## 21. Coverage and quality gates

Coverage is diagnostic rather than the specification. Initially, do not block
work on a blanket percentage. Instead require:

- every normative safety requirement mapped to a named test;
- every operation phase represented in restart/failure tables;
- every adapter parser with success, unsupported schema, malformed output, and
  process failure cases;
- every destructive action with stale cache and fresh-observation refusal;
- `vitest --run` and TypeScript checking passing from a clean environment.

Use V8 coverage to find untested branches in the pure core. Add a numeric
threshold later only if it reveals meaningful regression gaps rather than
encouraging low-value line execution.

## 22. Explicitly rejected testing approaches

### Real GitHub resources in automated tests

Rejected because credentials, network, rate limits, cleanup, and repository
ownership add substantial complexity while providing little signal beyond
adapter translation and manual acceptance.

### Real Kitty automation in Vitest

Rejected because focus/rendering behavior is visual and environment-dependent.
Typed Kitty calls and parsing are tested; actual UX is manually obvious.

### Real Worktrunk worktrees in the normal suite

Rejected because Worktrunk's behavior is external and real worktree lifecycle
is slower and riskier than scripted adapter outcomes. Disposable manual checks
cover integration.

### Semantic asynchronous hook event tests

Rejected because hooks are refresh opportunities, not authoritative deltas.
The system must remain correct if a hook is duplicated, delayed, or absent.

### Mocking every internal module

Rejected because it couples tests to implementation structure and can verify a
fictional call graph rather than behavior. Dependency injection occurs at
explicit adapter/store/clock/ID boundaries.

### Filesystem beneath every test

Rejected because JSON persistence is a narrow adapter concern. In-memory and
fault-injecting stores make domain tests faster, clearer, and more exhaustive.

## 23. Incremental test sequence

Tests grow with the runnable delivery sequence in the MVP specification. Do
not build the entire test infrastructure before Pi can demonstrate the first
behavior.

1. **Persist intent.** Register `/agents`, expose one creation action from its
   direct UI, and test the pure initial-record transition, UI delegation,
   atomic store create, fresh store reopen, and zero resource-adapter calls.
1. **Read it back.** Test registry enumeration, repository filtering,
   unknown-schema handling, and deterministic formatting before introducing
   external observation.
1. **Create Worktrunk resources.** Add the fake Worktrunk adapter, exact command
   contract fixtures, operation journal, verified resource append, and
   interruption/retry tests.
1. **Complete clean promotion.** Add scripted Pi-session and Kitty outcomes,
   test every continuation boundary, and prove activation occurs only after all
   required resources are verified.
1. **Observe status.** Add reconciliation tables, observation-cache merging,
   cache-first rendering, lifecycle reporting, and duplicate-tab cases.
1. **Stop and restore.** Add idempotence, restoration-definition contracts,
   duplicate-tab refusal, and fresh-service reboot tests.
1. **Create supporting agents.** Reuse the provisioning harness with a
   manager-assigned `parentAgentId`, prove lifecycle launch carries no
   assignment, and add non-cascading relationship-integrity cases.
1. **Switch branches.** Add explicit association, plural branch/PR resources,
   `git switch` preflight/contract tests, and unchanged agent/worktree identity.
1. **Delete safely.** Add plural GitHub normalization, fresh destructive planning,
   fault-injected resource journals, and interruption after every action.

Each step ends with both a short manual Pi demonstration and a focused Vitest
suite. Shared fakes, builders, and interfaces are extracted when the current
increment needs them; they are not speculative prerequisites. Real temporary
directories remain limited to the durable-store and restart contracts, and
real external tools remain outside `vitest --run`.

Subcommand vocabulary may be added or renamed independently of this sequence.
When a subcommand is introduced, its tests cover only routing and interactive
selection; the selected UUIDs enter the already-tested application operation.

## 24. Acceptance criteria for the strategy

1. `vitest --run` succeeds with network disabled and without a Kitty instance,
   GitHub credentials, Worktrunk mutation, or an interactive Pi process.
1. A new reconciliation case requires only plain input/output values.
1. Every external success/failure/uncertain outcome can be scripted through a
   typed fake adapter.
1. Every multi-phase operation can be interrupted at each phase and reopened by
   a fresh service instance.
1. Stale cached safety state is rejected by every destructive operation.
1. Two concurrent durable writers cannot silently lose an update.
1. Out-of-order refresh completion cannot regress newer per-source cache state.
1. Missing/corrupt cache never makes a durable agent disappear.
1. Adapter tests prove safe command construction without running the command.
1. Pi UI tests remain small and actual UI behavior has an explicit manual
   checklist.
1. Branch/PR plurality never weakens one-worktree cardinality or per-resource
   cleanup evidence.
1. Delegation tests prove no cascading resource ownership/deletion and no
   unauthorized sibling or unrelated-tree communication.
1. No automated test reads user home/XDG/Pi/Kitty/GitHub state.
1. The suite remains fast enough to run continuously during extension
   development.

## 25. References

- [Pi coding-agent package and Vitest test command](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/package.json)
- [Pi coding-agent source and tests](https://github.com/earendil-works/pi/tree/main/packages/coding-agent)
- [Vitest documentation](https://vitest.dev/guide/)
- [MVP design](agents-design.md)
- [Archive lifecycle](agents-archive.md)
- [Dirty/non-default promotion](agents-transactional-promotion.md)
- [Multi-repository control](agents-multi-repo-control.md)
- [Delegation and communication security](agents-delegation-communication.md)
