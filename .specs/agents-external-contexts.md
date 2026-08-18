# Agents: External Contexts Feature Specification

Status: deferred additive feature  
Depends on: `agents-design.md` MVP  
Implementation home: `razor-x/dotfiles/local/agents`

## 1. Purpose

An external context is a durable, structured association between a managed
agent and a specific object in another system, such as a Linear issue, Slack
thread, or GitHub issue.

The association supports workflows such as launching agents from a link,
attaching context retrospectively, and asking a controller, “How many agents
are working on this ticket?”

The local agent registry remains the control plane. External systems provide
context and capabilities; they do not own managed agents or define their
lifecycle.

## 2. Settled decisions

1. An agent may reference any number of external contexts, and one external
   context may be referenced by any number of agents.
2. Context identity uses stable provider-native identity, not display text.
3. Fetched labels, issue keys, status, and other presentation metadata are
   disposable observations.
4. External contexts are associations, not agent-owned resources. Agent
   deletion must never modify the referenced external object.
5. The agents extension persists generic context records and associations so
   they remain available after restart and without the orchestration layer.
6. Orchestration and communication extensions may resolve, attach, detach, and
   query contexts only through typed agents operations.
7. Provider adapters own URL recognition, canonical identity resolution, and
   observation. They do not own agent lifecycle.
8. Pi session content does not substitute for this metadata: it is
   unstructured, may be compacted, and is not queryable across agents.
9. Provider failure must not block listing, stopping, restoring, archiving, or
   deleting agents.
10. Context associations do not affect `parentId`, topics, resource ownership,
    or cleanup eligibility.

## 3. Data model

Agent records add durable associations:

```ts
type ManagedAgentRecord = {
  // Existing fields omitted.
  externalContextIds: ContextId[];
};
```

External contexts are globally enumerable records:

```ts
type ExternalContextRecordV1 = {
  schemaVersion: 1;
  id: ContextId;
  revision: number;

  provider: string;   // "linear", "slack", "github", ...
  kind: string;       // "issue", "thread", ...
  externalId: string; // stable provider-native identity
  url: string;

  createdAt: string;
  updatedAt: string;
};
```

The unique logical identity is `(provider, kind, externalId)`. Human-facing
keys such as `ENG-482` are observations unless the provider guarantees their
stability. Equivalent URLs for one object must resolve to the same context.

Fetched presentation state is stored separately:

```ts
type ExternalContextObservation = {
  contextId: ContextId;
  label?: string;
  state?: string;
  observedAt: string;
  error?: string;
};
```

When observation is missing or stale, the UI falls back to the stored URL and
external ID. Cached state never authorizes agent or external-system mutation.

The initial implementation finds associated agents by scanning the expected
small set of globally enumerable records. It does not need a reverse index,
database, daemon, or webhook service.

## 4. Operations

The application layer exposes typed operations equivalent to:

```ts
resolveExternalContext(input);
attachExternalContext(agentIds, contextInput);
detachExternalContext(agentIds, contextId);
listAgents({ externalContextId, scope? });
```

Attachment resolves the input through an available provider adapter, reuses an
existing context record with the same canonical identity, and adds its ID to
each selected agent idempotently.

Context may be attached during creation or retrospectively:

- “Launch two agents for this Linear issue.”
- “Attach this Slack thread to the current agent.”
- “These three agents are working on ENG-482.”
- “Which agents are associated with this thread?”

Agent creation accepts initial context associations and persists them with the
provisioning record. Child creation does not create live inheritance. An
orchestrator may explicitly copy the parent's contexts; later changes do not
cascade.

## 5. Controller queries and presentation

Given a URL or provider identifier, a controller resolves canonical context
identity and filters agent records by `externalContextIds`. It reports lifecycle
categories rather than one ambiguous count:

```text
ENG-482 — Fix refresh-token races
3 associated agents: 2 running, 1 stopped

  investigate backend behavior   running
  database prototype             waiting
  client compatibility           stopped
```

“Working on this context” means currently registered agents associated with
it. Archived agents are reported separately as historical work when archive
support exists.

One agent may reference several contexts, for example a Linear issue as the
work item and a Slack thread containing relevant discussion. No context is
implicitly primary. A separate topic may provide the informal grouping label.

`/agents` may display cached context labels and links, filter by a selected
context, and invoke the same typed operations available to controllers. No
separate TUI is required.

## 6. Provider boundary

An external-context provider adapter may:

- recognize supported URLs or identifiers;
- return stable provider identity and a canonical URL;
- observe presentation metadata such as title and current state;
- produce a display link.

Attaching context never creates, updates, closes, comments on, or deletes the
external object. Any future mutation requires a separate explicit operation,
authorization policy, and confirmation behavior.

The agents extension must remain able to display stored references and manage
agents without Linear, Slack, GitHub, credentials, network access, or the
orchestration extension currently loaded.

## 7. Lifecycle interactions

- **Stop and restore:** preserve associations unchanged.
- **Delete:** remove the agent associations but never mutate external objects.
- **Archive:** snapshot canonical context references so historical association
  remains meaningful if active context records are later removed.
- **Multi-repository control:** one context may associate agents in several
  repositories. Queries resolve the context first and then apply the current
  controller scope.

Empty context-record cleanup is optional housekeeping and must not affect
external systems.

## 8. Testing strategy

Follow `agents-testing-strategy.md`:

- pure tests cover canonical identity, idempotent attachment, detachment,
  filtering, and lifecycle counts;
- fake provider adapters resolve different inputs to one canonical context and
  simulate unavailable, malformed, and stale providers;
- temporary-store tests prove records and associations survive restart while
  corrupt observation caches are ignored;
- the normal suite never contacts Linear, Slack, or GitHub;
- manual acceptance checks cover Pi selection and link presentation.

## 9. Incremental delivery

1. Add generic context records and attach/detach/query operations using
   manually supplied provider identity.
2. Add the first provider resolvers, likely Linear issues and Slack threads.
3. Allow orchestration to launch agents with contexts and answer cross-agent
   context queries.
4. Add provider observation caches for richer presentation.
5. Extend archive snapshots and multi-repository presentation when those
   features are implemented.

## 10. Acceptance criteria

1. Equivalent references to one Linear issue produce one external context.
2. A controller can report associated agents and their lifecycle states for a
   Linear issue or Slack thread.
3. Associations persist across Pi and machine restarts.
4. Provider failure leaves all core agent lifecycle operations functional.
5. Deleting an agent never mutates a referenced external object.
6. One agent may reference multiple contexts.
7. One context may associate agents from multiple repositories.

## 11. References

- [MVP design](agents-design.md)
- [Testing strategy](agents-testing-strategy.md)
- [Archive lifecycle](agents-archive.md)
- [Multi-repository control](agents-multi-repo-control.md)
- [Topics](agents-topics.md)
- [Runtime dependency policy](agents-dependency-policy.md)

