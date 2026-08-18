# Agents: Delegation and Communication Security Specification

Status: deferred feature and blocking security specification\
Depends on: `agents-design.md` and `agents-multi-repo-control.md`\
Applies to: managed agents, supporting agents, and unmanaged root controllers

## 1. Purpose

The `agents` extension owns durable managed-agent identity, one-worktree
lifecycle, flat resource references, delegation relationships, and observed
status. It should not also become a task planner or conversational workflow
engine.

A small companion layer may nevertheless need to deliver assignments, updates,
questions, and results among Pi sessions. That layer must prevent a
confused-deputy escape:

> A narrowly sandboxed agent must not be able to contact an unrelated, more
> privileged agent and induce it to operate in another permission scope.

This specification separates lifecycle from orchestration and defines the
minimum authorization boundary for inter-agent communication. It does not
require a workspace aggregate, stored controller nodes, a `lineageId`, or a
large orchestration service. The intended product shape is an inter-agent
communication extension plus an orchestration skill, backed by the smallest
transport that can enforce these rules.

## 2. Settled boundaries

### 2.1 `agents` lifecycle manager

The `agents` extension provides:

- creation and lifecycle operations;
- stable managed-agent UUIDs represented by `agentId`;
- manager-assigned `parentAgentId: AgentId | null` relationships;
- flat resource and observed-status queries;
- branch/PR association and sequential branch switching;
- focus, resume, stop, archive, and delete operations; and
- relationship-integrity operations such as reparent and detach.

It does not create controller identities, decompose tasks, choose roles, deliver
assignments, interpret progress, collect results, or synthesize completion.

### 2.2 Communication extension

The communication extension provides:

- authenticated cross-process delivery;
- ancestry-based route authorization for managed-agent senders;
- separately authorized operator-origin delivery from an unmanaged controller;
- delivery modes for assignment, requirement, question, progress, completion,
  and result messages;
- correlation and bounded delivery status; and
- a local Pi delivery sink after authorization.

It does not own worktrees, branches, PRs, Pi sessions, tabs, or agent lifecycle.
It queries manager-owned identity and relationship state rather than recreating
an agent registry. It does not invent a `ControllerId` to represent operator
traffic.

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
1. **Delegation ancestry.** Managed agents form a forest through
   `parentAgentId: AgentId | null`; ancestry is recovered by following that
   chain and may cross repositories.
1. **Git topology.** Repositories, worktrees, branches, commits, and PRs relate
   independently of delegation.

A child may work in another repository or on a Git-sibling branch/PR. A Git
relationship does not create delegation. Neither structure transfers resource
ownership or creates a workspace object.

## 4. Managed-agent identity and parentage

Only managed agents are nodes in the delegation forest:

```ts
type AgentId = string;

type AgentDelegationIdentity = {
  agentId: AgentId;
  parentAgentId: AgentId | null;
};
```

The field names are settled. Agent-domain schemas do not use a bare `id` key.
There is no `ControllerId` or `lineageId`. Top-level agents have
`parentAgentId: null`, and tree membership is derived by following parent links
to a top-level agent.

The relationship means delegation provenance and current coordination. It does
not mean filesystem containment, repository containment, process containment,
or ownership of a child or any child resource.

### 4.1 Manager authority

Only manager code may:

- mint an `agentId`;
- choose `parentAgentId` from authenticated creation context;
- reparent or detach an agent;
- reject cycles or dangling parent references; or
- issue, rotate, and revoke transport registrations/capabilities.

Model-callable schemas do not accept a raw `parentAgentId`. Direct edits to
agent records, Pi-session metadata, environment variables, or message bodies
are not identity mutations and provide no authorization.

The communication authorizer must use a manager-issued relationship view that
an agent sandbox cannot rewrite. If ordinary registry files are writable by a
sender, those files are descriptive state rather than communication
authorization evidence.

Reparenting changes the one affected root link after validating the resulting
forest. Detachment sets `parentAgentId: null`. Either operation rotates affected
communication capabilities atomically before delivery resumes; no subtree-wide
family identifier needs updating.

### 4.2 Unmanaged root controller

A Pi session in a primary worktree or parent directory may coordinate managed
agents without becoming one. It remains outside the delegation forest and has:

- no agent or controller record;
- no stable `ControllerId`;
- no `parentAgentId`;
- no managed worktree, Pi-session, branch, PR, Kitty-tab, or child resource;
  and
- no managed-agent restore or delete lifecycle.

Agents created directly by this session are top-level agents with
`parentAgentId: null`. If the communication layer permits the session to send
assignments, it authenticates a local **operator connection/capability** whose
scope is established independently. Operator-origin delivery does not claim an
agent sender and does not insert a synthetic parent node.

Durable grouping of work initiated by an unmanaged controller is an optional
orchestration-layer concern, not delegation or resource ownership.

## 5. Communication authorization policy

For managed-agent traffic, let `senderAgentId` be derived by the transport and
`recipientAgentId` be the exact registered destination.

Delivery is allowed by default only when:

- the sender is an ancestor of the recipient; or
- the recipient is an ancestor of the sender.

Consequences:

- parents may communicate with descendants;
- children may communicate with ancestors;
- agents in unrelated delegation trees may not communicate;
- siblings may not communicate directly;
- siblings route through a common parent, which receives one authorized message
  and decides whether to emit a separate authorized message to the sibling; and
- knowledge of another agent's UUID or metadata is insufficient.

Sharing a top-level ancestor is not sufficient authorization: siblings share a
root but still fail the direct ancestry check. The check is code, not prompt,
policy text, or model judgment. Missing, ambiguous, cyclic, stale,
unknown-schema, or partially updated relationship state fails closed.

Operator-origin delivery is a separate route. It is authorized against the
operator connection's trusted management scope and is labeled as operator
origin; it never masquerades as an agent or changes `parentAgentId`. A managed
agent capability cannot invoke this route.

Explicit peer grants are deferred. If added, they must be manager-issued,
narrowly scoped, revocable capabilities; they must not be represented by
silently changing Git topology or pretending siblings are ancestors.

## 6. Sender authentication and transport boundary

Message bodies cannot establish sender identity. A managed-agent request may
contain a recipient, message kind, correlation ID, and bounded payload, but no
caller-controlled authoritative sender field:

```ts
type OutboundAgentMessageRequest = {
  recipientAgentId: AgentId;
  messageKind:
    | "assignment"
    | "requirement"
    | "question"
    | "progress"
    | "completion"
    | "result";
  correlationMessageId?: string;
  payload: unknown;
};

type AuthenticatedAgentDelivery = OutboundAgentMessageRequest & {
  senderAgentId: AgentId; // added by transport code
  deliveredAt: string;
};

type AuthenticatedOperatorDelivery = OutboundAgentMessageRequest & {
  origin: "operator";
  deliveredAt: string;
};
```

The transport derives `senderAgentId` from one of:

- a manager-registered connection whose agent was fixed at registration; or
- an unforgeable, agent-scoped capability presented outside the message body.

The operator route likewise derives authority from its registered local
connection/capability, not a controller ID in the body.

Authorization executes at the receiving broker/transport boundary before any
message reaches Pi. Caller-provided `senderAgentId`, `from`, `parentAgentId`,
worktree, session, repository, or operator-origin fields are rejected or
ignored as untrusted payload, never used as authority.

### 6.1 Capability isolation

All arbitrary code in an agent sandbox can act with that agent's own
communication capability. That is expected. It must not be able to obtain or
forge another agent's or an operator connection's capability.

Therefore:

- capabilities and authoritative connection mappings do not live in a registry
  or mailbox readable by unrelated agent sandboxes;
- a shared agents state directory is not a communication trust root;
- bearer material is never logged, placed in message content, persisted in Pi
  history, or returned by resource/status queries;
- reconnect rotates or re-proves agent binding according to transport policy;
- replay protection and bounded message sizes/rates are enforced by code; and
- knowing a broker socket/address grants no authority to send.

If the selected transport cannot isolate credentials or maintain an
authoritative manager-issued relationship view outside sender-writable state,
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

The extension derives visible origin metadata from the authenticated delivery.
The payload cannot override it. While Pi is busy, delivery uses explicit
`steer` or `followUp` semantics rather than racing the local agent loop.

A newly launched supporting agent receives no task in Kitty/Pi process
arguments. The lifecycle manager first creates and registers the child Pi
session and communication capability; the communication layer then delivers
the initial assignment.

## 8. Supporting-agent creation requests

A child may intentionally ask its own parent to create work within the parent's
authority. That ancestor route is allowed. It does not let the child choose an
arbitrary parent or repository permission scope.

When the authorizing parent accepts, manager code chooses one of two placements:

1. **Requester-managed support.** Make the new agent a child of the requester
   when the requester should coordinate it.
1. **Parent-coordinated parallel support.** Make the new agent another child of
   the authorizing parent when the parent should coordinate parallel work.

A model may express coordination intent through a closed enum, but the manager
derives all concrete agent IDs from the authenticated requester and authorizer.
The request body cannot name a different `parentAgentId`.

An unmanaged operator may create a top-level agent, but cannot create a child by
pretending to have an agent ID. To place work under an existing managed parent,
that managed parent must be the authenticated authorizer under the ordinary
creation policy.

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

Before a parent agent disappears from the live relationship graph, every direct
child must be handled explicitly by one of:

- independent child deletion/archive;
- reparenting under another authorized managed agent; or
- detachment as a top-level agent with `parentAgentId: null`.

A plan that selects a parent does not silently add children. If parent and child
independently qualify for the same confirmed policy, child-first execution is
referential-integrity ordering only.

Reparent/detach is a manager operation, not a resource action. It updates the
parent link and affected capabilities atomically or leaves the old relationship
in force. Historical archive/operation snapshots may retain prior agent IDs as
provenance without granting live authority.

## 10. Normative requirements

| ID    | Requirement                                                                                                                                                                                     |
| ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DC-01 | Every managed agent shall own exactly one canonical worktree; delegation shall never alter that cardinality or transfer resources.                                                              |
| DC-02 | Every managed agent shall have manager-assigned `agentId` and nullable `parentAgentId`; no controller or lineage identity shall be added to the agent graph.                                    |
| DC-03 | Models and message bodies shall not select or mutate concrete `parentAgentId`, `senderAgentId`, operator origin, or capabilities.                                                               |
| DC-04 | The transport shall derive managed sender identity from a registered connection or agent-scoped capability before parsing message semantics.                                                    |
| DC-05 | Delivery authorization shall be enforced in code against an authoritative manager-issued parent graph.                                                                                          |
| DC-06 | Ancestor-to-descendant and descendant-to-ancestor managed-agent delivery shall be allowed, subject to ordinary payload/rate policy.                                                             |
| DC-07 | Direct sibling and unrelated-tree delivery shall be denied by default.                                                                                                                          |
| DC-08 | Sibling communication shall route as two separately authorized messages through a common parent.                                                                                                |
| DC-09 | Sharing a top-level ancestor shall never authorize direct delivery without an ancestor/descendant relationship.                                                                                 |
| DC-10 | Names, UUID knowledge, Pi-session paths, worktree paths, branches, PRs, Kitty metadata, and broker addresses shall grant no communication authority.                                            |
| DC-11 | Authoritative capability and connection state shall not be writable or readable across unrelated agent sandboxes.                                                                               |
| DC-12 | Missing, stale, ambiguous, cyclic, unknown-schema, or partially changed relationship state shall fail closed.                                                                                   |
| DC-13 | Reparent/detach shall validate the resulting forest, update affected parent links, and rotate affected capabilities atomically.                                                                 |
| DC-14 | Parent deletion/archive shall never select or mutate child resources implicitly.                                                                                                                |
| DC-15 | A parent record shall not disappear while an unresolved live `parentAgentId` points to it.                                                                                                      |
| DC-16 | An unmanaged root controller shall have no agent/controller record, stable controller ID, delegation parent, managed resources, or lifecycle.                                                   |
| DC-17 | Supporting-agent lifecycle launch shall contain no task assignment; assignment shall occur only after child identity/connection registration.                                                   |
| DC-18 | A child request for additional support shall be sent only to an ancestor and shall result in requester-child or authorizer-child placement computed by manager code.                            |
| DC-19 | The communication layer shall use exact registered agent IDs for routing and shall not infer delegation from Git/repository topology.                                                           |
| DC-20 | Message envelopes shall be closed, versioned, bounded, replay-aware, and shall not treat payload metadata as authorization.                                                                     |
| DC-21 | Delivery into Pi shall occur only after authentication/authorization and shall use explicit idle/steer/follow-up semantics.                                                                     |
| DC-22 | Operator-origin delivery shall use a separately registered local connection/capability, shall be visibly distinct from an agent sender, and shall be unavailable to managed-agent capabilities. |
| DC-23 | Peer grants, if later added, shall be explicit manager-issued capabilities and default to absence.                                                                                              |

## 11. Failure handling

- If sender authentication fails, deliver nothing and disclose no recipient
  metadata beyond a bounded denial.
- If ancestry cannot be resolved freshly, fail closed rather than trusting a
  cached or caller-supplied parent graph.
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
1. shared top-level ancestor without direct ancestry: denied;
1. unrelated tree with known UUID/socket/path: denied;
1. forged `senderAgentId`, `parentAgentId`, or operator origin in payload:
   denied/ignored;
1. stale/revoked/replayed capability: denied;
1. model attempt to create with arbitrary `parentAgentId`: schema refusal;
1. root controller has no stored identity, and its operator connection cannot be
   used from a managed-agent capability;
1. requester-managed versus parent-coordinated placement;
1. reparent/detach capability rotation and atomic parent-link update;
1. parent delete/archive never adding a child candidate; and
1. authorized delivery reaching `pi.sendUserMessage()` only after the policy
   decision.

Manual acceptance uses disposable agents with intentionally different nono
permission scopes. A narrow child must fail to contact an unrelated privileged
agent even when given its name, UUID, Pi-session path, worktree path, and broker
address. The same child must be able to contact its own parent and request
parent-authorized supporting work. An unmanaged root controller may use only
its own operator connection and never appears as an agent sender.

## 13. Open implementation choices

These choices do not weaken the settled policy:

1. Cross-process transport: per-session sockets, a small broker, capability
   mailboxes, or another mechanism that satisfies capability isolation.
1. At-most-once versus idempotent at-least-once delivery for each message kind.
1. Whether result messages use custom Pi messages or user messages.
1. The representation and scope of operator-connection authorization.
1. Future explicit peer-grant representation and expiry.
1. Optional durable orchestration grouping for work initiated by an unmanaged
   root controller, without adding a controller record.

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
