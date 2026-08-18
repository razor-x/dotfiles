# Agents: Delegation and Communication Security Specification

Status: deferred feature and blocking security specification\
Depends on: `agents-design.md` and `agents-multi-repo-control.md`\
Applies to: managed agents, supporting agents, and unmanaged root controllers

## 1. Purpose

The `agents` extension owns durable agent identity, one-worktree lifecycle, flat
resource references, delegation relationships, and observed status. It should
not also become a task planner or conversational workflow engine.

A small companion layer may nevertheless need to deliver assignments, updates,
questions, and results among Pi sessions. That layer must prevent a
confused-deputy escape:

> A narrowly sandboxed agent must not be able to contact an unrelated, more
> privileged agent and induce it to operate in another permission scope.

This specification separates lifecycle from orchestration and defines the
minimum authorization boundary for inter-agent communication. It does not
require a workspace aggregate or a large orchestration service. The intended
product shape is an inter-agent communication extension plus an orchestration
skill, backed by the smallest transport that can enforce these rules.

## 2. Settled boundaries

### 2.1 `agents` lifecycle manager

The `agents` extension provides:

- creation and lifecycle operations;
- stable managed-agent UUIDs;
- optional internal controller UUIDs;
- manager-assigned delegation relationships;
- flat resource and observed-status queries;
- branch/PR association and sequential branch switching;
- focus, resume, stop, archive, and delete operations; and
- relationship-integrity operations such as reparent and detach.

It does not decompose tasks, choose roles, deliver assignments, interpret
progress, collect results, or synthesize completion.

### 2.2 Communication extension

The communication extension provides:

- authenticated cross-process delivery;
- lineage-based route authorization;
- delivery modes for assignment, requirement, question, progress, completion,
  and result messages;
- correlation and bounded delivery status; and
- a local Pi delivery sink after authorization.

It does not own worktrees, branches, PRs, Pi sessions, tabs, or agent lifecycle.
It queries manager-owned identity and relationship state rather than recreating
an agent registry.

### 2.3 Orchestration skill

An orchestration skill provides model-facing guidance for:

- task decomposition;
- choosing sequential versus parallel supporting work;
- deciding who should coordinate newly requested work;
- requirement broadcasts;
- question/progress handling; and
- completion/result synthesis.

The skill can request typed lifecycle and communication operations. Prompts are
never an authorization mechanism.

## 3. Independent structures

The design contains three deliberately separate structures:

1. **Resource ownership.** Each managed agent owns exactly one worktree and its
   own Pi session, branch/PR resources, and tab.
1. **Delegation lineage.** Agents and optional controllers form a coordination
   hierarchy that may cross repositories.
1. **Git topology.** Repositories, worktrees, branches, commits, and PRs relate
   independently of delegation.

A child may work in another repository or on a Git-sibling branch/PR. A Git
parent/child relationship does not create delegation. Neither structure
transfers resource ownership or creates a workspace object.

## 4. Delegation principals and identity

A **delegation principal** is either:

- a managed agent identified by its stable agent UUID; or
- an internal controller identified by a stable controller UUID for the life of
  its registered coordination identity.

Conceptually, both have:

```ts
type DelegationIdentity = {
  parentId: AgentId | ControllerId | null;
  lineageId: string;
};
```

`parentId` is the provisional field spelling. `spawnedByAgentId` remains an
open alternative, although it is type-inaccurate when a controller can be the
parent unless it becomes a broader `spawnedByPrincipalId`.

The relationship means delegation provenance and current coordination. It does
not mean filesystem containment, repository containment, process containment,
or ownership of a child or any child resource.

### 4.1 Manager authority

Only trusted manager code may:

- mint an agent/controller UUID;
- choose a principal's parent;
- assign its lineage ID;
- reparent or detach a principal;
- update a moved subtree's lineage; or
- issue, rotate, and revoke transport registrations/capabilities.

Model-callable schemas do not accept raw `parentId` or `lineageId` values.
Direct edits to agent records, Pi-session metadata, environment variables, or
message bodies are not identity mutations and provide no authorization.

### 4.2 Lineage ID

`lineageId` is a manager-assigned tree identifier and a fast cross-tree denial
key. It is not sufficient authorization by itself because siblings share a
lineage but may not communicate directly.

Within-tree authorization still requires an ancestry check over manager-owned
parent edges. Reparenting within one tree may retain the lineage ID. Moving a
subtree to another tree or detaching it as a new root updates the entire moved
subtree atomically and rotates affected capabilities before communication
resumes.

### 4.3 Root controller

A Pi session in a primary worktree or parent directory may coordinate managed
agents without becoming one. If communication requires a stable root sender,
the manager registers an internal controller identity.

A controller identity:

- may be a delegation parent and communication principal;
- owns no repository, worktree, Pi session, branch, PR, Kitty tab, or agent;
- has no managed-agent lifecycle or restore operation;
- is not shown as a managed agent in `/agents`; and
- does not create a workspace aggregate.

Lifecycle management alone need not mint a controller. Whether a controller ID
survives process restart, and whether an orchestration layer durably groups work
under it, remain optional orchestration choices.

## 5. Communication authorization policy

Let `sender` be the principal derived by the transport and `recipient` be the
exact registered destination.

Delivery is allowed by default only when:

- sender is an ancestor of recipient; or
- recipient is an ancestor of sender.

Consequences:

- parents/controllers may communicate with descendants;
- children may communicate with ancestors;
- unrelated delegation trees may not communicate;
- siblings may not communicate directly;
- siblings route through a common parent, which receives one authorized message
  and decides whether to emit a separate authorized message to the sibling; and
- knowledge of another principal's UUID or metadata is insufficient.

The check is code, not prompt, policy text, or model judgment. Missing,
ambiguous, cyclic, stale, unknown-schema, or partially updated relationship
state fails closed.

Explicit peer grants are deferred. If added, they must be manager-issued,
narrowly scoped, revocable capabilities; they must not be represented by
silently changing Git topology or pretending siblings are ancestors.

## 6. Sender authentication and transport boundary

Message bodies cannot establish sender identity. A transport-facing request may
contain a recipient, message kind, correlation ID, and bounded payload, but no
caller-controlled authoritative sender field:

```ts
type OutboundMessageRequest = {
  recipientId: AgentId | ControllerId;
  kind:
    | "assignment"
    | "requirement"
    | "question"
    | "progress"
    | "completion"
    | "result";
  correlationId?: string;
  payload: unknown;
};

type AuthenticatedDelivery = OutboundMessageRequest & {
  senderId: AgentId | ControllerId; // added by transport code
  deliveredAt: string;
};
```

The transport derives `senderId` from one of:

- a manager-registered connection whose principal was fixed at registration; or
- an unforgeable, principal-scoped capability presented outside the message
  body.

Authorization executes at the receiving broker/transport boundary before any
message reaches Pi. A caller-provided `senderId`, `from`, lineage, worktree,
session, or repository field is rejected or ignored as untrusted payload, never
used as authority.

### 6.1 Capability isolation

All arbitrary code in an agent sandbox can act with that agent's own
communication capability. That is expected. It must not be able to obtain or
forge another principal's capability.

Therefore:

- capabilities and authoritative connection mappings do not live in a registry
  or mailbox readable by unrelated agent sandboxes;
- a shared agents state directory is not a communication trust root;
- bearer material is never logged, placed in message content, persisted in Pi
  history, or returned by resource/status queries;
- reconnect rotates or re-proves principal binding according to transport
  policy;
- replay protection and bounded message sizes/rates are enforced by code; and
- knowing a broker socket/address grants no authority to send.

If the selected transport cannot isolate credentials or maintain an
authoritative manager-owned relationship view outside sender-writable state,
it is incompatible with this specification.

## 7. Pi delivery

Pi's `pi.events` bus is process-local and can coordinate extensions loaded in
one Pi process; it is not an inter-agent transport.

After transport authentication and route authorization, the receiving
communication extension may use Pi's documented APIs:

- `pi.sendUserMessage()` for an assignment or conversational update that should
  trigger/queue a turn; or
- `pi.sendMessage()` for a typed custom message when custom rendering/context
  semantics are preferable.

The extension derives visible sender metadata from `AuthenticatedDelivery`.
The payload cannot override it. While Pi is busy, delivery uses explicit
`steer` or `followUp` semantics rather than racing the local agent loop.

A newly launched supporting agent receives no task in Kitty/Pi process
arguments. The lifecycle manager first creates and registers the child Pi
session and transport identity; the communication layer then delivers the
initial assignment.

## 8. Supporting-agent creation requests

A child may intentionally ask its own parent to create work within the parent's
authority. That ancestor route is allowed. It does not let the child choose an
arbitrary parent, repository permission scope, or lineage.

When the authorizing parent accepts, manager code chooses one of two placements:

1. **Requester-managed support.** Make the new agent a child of the requester
   when the requester should coordinate it.
1. **Parent-coordinated parallel support.** Make the new agent another child of
   the authorizing parent when the parent should coordinate parallel work.

A model may express the coordination intent through a closed enum, but the
manager derives all concrete principal IDs from the authenticated requester and
authorizer. The request body cannot name a different parent or lineage.

The new agent independently owns exactly one worktree and all of its other
resources. Its repository and Git relationship are explicit lifecycle inputs
and may be:

- another worktree in the same repository;
- a worktree in another repository; or
- a branch/PR structurally sibling to the requester's Git work.

None of those choices changes delegation authorization.

## 9. Lifecycle and relationship integrity

Parent/child relationships never cascade stop, archive, delete, branch cleanup,
PR cleanup, or worktree removal.

Before a parent principal disappears from the live relationship graph, every
direct child must be handled explicitly by one of:

- independent child deletion/archive;
- reparenting under another authorized principal; or
- detachment as a new lineage root.

A plan that selects a parent does not silently add children. If parent and child
independently qualify for the same confirmed policy, child-first execution is
referential-integrity ordering only.

Reparent/detach is a manager operation, not a resource action. It updates the
relationship graph and capabilities atomically or leaves the old relationship
in force. Historical archive/operation snapshots may retain prior IDs as
provenance without granting live authority.

## 10. Normative requirements

| ID    | Requirement |
| ----- | ----------- |
| DC-01 | Every managed agent shall own exactly one canonical worktree; delegation shall never alter that cardinality or transfer resources. |
| DC-02 | Every agent/controller communication principal shall have manager-assigned parent and lineage identity. |
| DC-03 | Models and message bodies shall not select or mutate concrete parent IDs, lineage IDs, sender IDs, or capabilities. |
| DC-04 | The transport shall derive sender identity from a registered connection or principal-scoped capability before parsing message semantics. |
| DC-05 | Delivery authorization shall be enforced in code against the authoritative manager-owned ancestry graph. |
| DC-06 | Ancestor-to-descendant and descendant-to-ancestor delivery shall be allowed, subject to ordinary payload/rate policy. |
| DC-07 | Direct sibling and unrelated-tree delivery shall be denied by default. |
| DC-08 | Sibling communication shall route as two separately authorized messages through a common parent. |
| DC-09 | `lineageId` alone shall never authorize delivery. |
| DC-10 | Names, UUID knowledge, Pi-session paths, worktree paths, branches, PRs, Kitty metadata, and broker addresses shall grant no communication authority. |
| DC-11 | Authoritative capability and connection state shall not be writable or readable across unrelated agent sandboxes. |
| DC-12 | Missing, stale, ambiguous, cyclic, unknown-schema, or partially changed relationship state shall fail closed. |
| DC-13 | Reparent/detach across trees shall atomically update the moved subtree's lineage and rotate affected capabilities. |
| DC-14 | Parent deletion/archive shall never select or mutate child resources implicitly. |
| DC-15 | A parent record shall not disappear while an unresolved live child edge points to it. |
| DC-16 | An internal root controller identity shall own no managed-agent resources or lifecycle. |
| DC-17 | Supporting-agent lifecycle launch shall contain no task assignment; assignment shall occur only after child identity/connection registration. |
| DC-18 | A child request for additional support shall be sent only to an ancestor and shall result in requester-child or authorizer-child placement computed by manager code. |
| DC-19 | The communication layer shall use exact registered principal IDs for routing and shall not infer delegation from Git/repository topology. |
| DC-20 | Message envelopes shall be closed, versioned, bounded, replay-aware, and shall not treat payload metadata as authorization. |
| DC-21 | Delivery into Pi shall occur only after authentication/authorization and shall use explicit idle/steer/follow-up semantics. |
| DC-22 | Peer grants, if later added, shall be explicit manager-issued capabilities and default to absence. |

## 11. Failure handling

- If sender authentication fails, deliver nothing and disclose no recipient
  metadata beyond a bounded denial.
- If ancestry cannot be resolved freshly, fail closed rather than trusting a
  cached or caller-supplied lineage.
- If transport delivery is uncertain, use a correlation/message ID and
  idempotent receipt rules; never inject the same assignment repeatedly merely
  because acknowledgement was lost.
- If Pi is stopped, return a typed unavailable/queued result according to the
  chosen transport policy. Communication does not silently restore an agent.
- If reparenting or capability rotation is interrupted, retain or reconstruct
  the last complete authorized graph before accepting messages.
- Communication failure does not rewrite resource ownership or agent lifecycle.

## 12. Testing and acceptance

Automated tests use fake connections, capabilities, manager state, and Pi
message sinks. At minimum they cover:

1. parent to direct child and deeper descendant: allowed;
1. child to parent and higher ancestor: allowed;
1. sibling to sibling: denied;
1. sibling relay through parent as two messages: allowed;
1. same `lineageId` without ancestry: denied;
1. unrelated lineage with known UUID/socket/path: denied;
1. forged `senderId`, `parentId`, or `lineageId` in payload: denied/ignored;
1. stale/revoked/replayed capability: denied;
1. model attempt to create with arbitrary parent/lineage: schema refusal;
1. root controller communicating with descendants while its resource set is
   structurally impossible;
1. requester-managed versus parent-coordinated placement;
1. reparent/detach capability rotation and atomic subtree lineage updates;
1. parent delete/archive never adding a child candidate; and
1. authorized delivery reaching `pi.sendUserMessage()` only after the policy
   decision.

Manual acceptance uses disposable agents with intentionally different nono
permission scopes. A narrow child must fail to contact an unrelated privileged
agent even when given its name, UUID, Pi-session path, worktree path, and broker
address. The same child must be able to contact its own parent and request
parent-authorized supporting work.

## 13. Open implementation choices

These choices do not weaken the settled policy:

1. Field spelling: `parentId` versus `spawnedByAgentId` (or the controller-safe
   `spawnedByPrincipalId`). If reparenting changes the live edge, immutable
   provenance may additionally remain in operation/archive history.
1. Cross-process transport: per-session sockets, a small broker, capability
   mailboxes, or another mechanism that satisfies capability isolation.
1. Ephemeral versus restart-stable internal controller identities.
1. At-most-once versus idempotent at-least-once delivery for each message kind.
1. Whether result messages use custom Pi messages or user messages.
1. Future explicit peer-grant representation and expiry.
1. Optional durable orchestration grouping under an unmanaged root controller.

Pi's process-local `pi.events` bus, prompt-only rules, shared writable JSON
mailboxes without authenticated sender capabilities, and sender fields inside
message bodies are not viable transport choices.

## 14. References

- [MVP design](agents-design.md)
- [Multi-repository control](agents-multi-repo-control.md)
- [Testing strategy](agents-testing-strategy.md)
- [Kitty remote-control security boundary](agents-kitty-security.md)
- [Pi extension API](https://pi.dev/docs/latest/extensions)
- [Pi RPC mode](https://pi.dev/docs/latest/rpc)
