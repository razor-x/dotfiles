# Agents: Topics Feature Specification

Status: deferred additive feature\
Depends on: `agents-design.md` MVP\
Implementation home: `razor-x/dotfiles/local/agents`

## 1. Purpose

A topic is one optional, informal label describing what an agent is broadly
about. It lets the user recognize that independently created agents concern the
same higher-level idea without introducing another ownership hierarchy.

Topics are intentionally narrower than tags, projects, groups, missions, or
workspaces.

## 2. Settled decisions

1. Every agent has `topic: string | null`.
1. An agent has at most one topic; there is no tag collection.
1. A topic is plain user-facing text, not a separate persisted entity.
1. Known topics are derived from current agent records.
1. A topic does not own agents or resources and has no lifecycle behavior.
1. Topic assignment is independent of `parentAgentId`, repository, lifecycle,
   and external-context associations.
1. The agents extension owns the durable field. Controllers and orchestration
   extensions may set it only through typed agents operations.

## 3. Data model

The next agent-record schema adds:

```ts
type ManagedAgentRecord = {
  // Existing fields omitted.
  topic: string | null;
};
```

A topic must be trimmed and non-empty. Matching uses a normalized comparison
form while preserving the selected display spelling. UI flows should offer
existing topics before accepting a new value to reduce spelling variants.

Changing a topic updates only the selected agent records. Clearing the final
use of a topic implicitly removes it from the derived topic list; there is no
topic record to clean up.

## 4. Operations and presentation

The application layer exposes typed operations equivalent to:

```ts
setTopic(agentIds, topic | null);
listTopics(scope?);
listAgents({ topic, scope? });
```

The same operations support direct Pi interaction and controller requests such
as:

- “Set these three agents' topic to Authentication cleanup.”
- “Show agents under Authentication cleanup.”
- “Clear the topic from this agent.”

`/agents` may show the topic beside each agent and filter or group a view by a
selected topic:

```text
Topic: Authentication cleanup
  investigate backend behavior
  database prototype
  client compatibility
```

An ungrouped agent remains fully manageable. No custom TUI is required; initial
flows use Pi dialogs and the existing agent selector.

## 5. Lifecycle and delegation

Stop, restore, and resource reconciliation preserve the topic unchanged.
Deleting an agent removes its topic value as part of deleting the record and
has no effect on other agents.

Child creation does not create live topic inheritance. An orchestrator may
explicitly copy the parent's topic when creating a child, but later parent
changes do not cascade.

Archive metadata should snapshot the topic. Multi-repository views apply their
normal scope before deriving or grouping topics; identical topic text does not
create ownership across repositories.

## 6. Testing and acceptance

Follow `agents-testing-strategy.md`. Pure tests cover normalization, assignment,
clearing, derived topic enumeration, scope filtering, and deterministic
grouping. Store tests prove the field survives restart and schema migration.

Acceptance requires:

1. Three independent agents can receive one topic and render together.
1. One agent cannot accumulate several topics.
1. Setting or clearing a topic never mutates external resources.
1. Topic state survives Pi and machine restarts.
1. Agents without a topic remain visible and manageable.

## 7. References

- [MVP design](agents-design.md)
- [Testing strategy](agents-testing-strategy.md)
- [Archive lifecycle](agents-archive.md)
- [Multi-repository control](agents-multi-repo-control.md)
