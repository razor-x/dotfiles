# Agents: Runtime Dependency Policy

Status: companion implementation specification\
Applies to: MVP\
Implementation home: `razor-x/dotfiles/local/agents`

## Decision

The MVP shall add no third-party runtime npm dependencies. This is a pragmatic
default, not a permanent prohibition: the extension is small, Pi and Node
already provide the required primitives, and additional libraries would mostly
duplicate those facilities.

Pi-provided packages are host APIs rather than extension-owned runtime
dependencies. Vitest remains an allowed development dependency. The extension
still integrates with the installed `pi`, `wt`, `git`, `kitty`/`kitten`, and
`gh` programs.

## Implementation primitives

| Need                                   | Primitive                                                                                                                        |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Execute external commands              | `pi.exec(command, args, { cwd, signal, timeout })` behind a fakeable `CommandRunner`                                             |
| Validate tool input and persisted JSON | Pi-provided `typebox`; validate only the external-output fields consumed                                                         |
| Direct interaction                     | `pi.registerCommand`, `ctx.ui.select`, `confirm`, `input`, `notify`, `setStatus`, and `setTitle`                                 |
| Model interaction                      | `pi.registerTool` with TypeBox parameter schemas                                                                                 |
| Pi-session discovery and transfer      | `ctx.sessionManager`, `SessionManager.list`/`listAll`/`forkFrom`, `ctx.switchSession`, `pi.setSessionName`, and `pi.appendEntry` |
| Resume in a new Kitty tab              | Launch `pi --session <exact-path>` through the Kitty adapter                                                                     |
| IDs, paths, time, and JSON             | `node:crypto`, `node:path`, an injected `Clock`, and native JSON APIs                                                            |
| Durable files                          | `node:fs/promises`; write a restrictive temporary sibling, flush/close it, then rename it over the destination                   |
| State transitions                      | Pure TypeScript functions, discriminated unions, exhaustive `switch`, and `assertNever`                                          |

`pi.exec` shall receive executable and argument arrays, never a constructed
shell command. Adapters shall normalize command results into domain types and
remain independently fakeable.

The `/resume` implementation is not a generic agent picker. `/agents` should
use Pi's public dialog APIs initially. Natural-language tools may accept an
array of agent IDs for batch selection. If a richer picker is eventually
needed, build the smallest component from Pi TUI primitives rather than adding
another UI framework.

## Persistence and concurrency

Atomic replacement prevents a terminated process from leaving a truncated JSON
file. The MVP needs only the native temporary-file-and-rename pattern; it does
not need the additional retry and portability behavior of `atomically`.

Atomic replacement does not prevent two processes from overwriting changes
derived from the same revision. The MVP limits this risk by using one durable
file per agent, expected revisions, in-process write serialization, and fresh
observation immediately before mutations. Managed Pi processes do not write a
shared registry merely to report lifecycle status.

Do not add a general shared-registry lock or a cross-process lock package.
Where the MVP requires exclusion around Worktrunk or Git topology mutations,
implement the existing `LockManager` seam with an exclusive `node:fs` `mkdir`
lock and fail closed rather than automatically stealing a possibly stale lock.
This narrow repository lock does not participate in ordinary observation-cache
or per-agent record writes. A stale record revision must fail explicitly rather
than be overwritten. Reconsider a library only if crash recovery or genuine
writer contention makes this minimal policy inadequate.

## Dependencies deliberately deferred

- **Execa:** reconsider only if `pi.exec` proves insufficient for streaming,
  stdin, environment control, or subprocess-tree management.
- **XState, Redux, Immer, or similar:** the operation journal and uncertain
  external effects are clearer as explicit domain state and pure transitions.
- **Zod or Ajv:** TypeBox already supplies shared static and runtime schemas.
- **Lowdb or another database wrapper:** native versioned JSON files match the
  storage and recovery model directly.
- **Simple Git or Octokit:** use structured `git` and `gh` output through the
  existing adapters and their installed authentication.
- **`atomically` or `proper-lockfile`:** add only after a demonstrated storage
  or multi-process failure that the native store contract cannot address
  cleanly.
- **A separate TUI library:** Pi owns the interaction surface.

A new runtime dependency must address a concrete missing capability, remove a
meaningful amount of correctness-sensitive code, remain behind an existing
adapter or store seam, and include tests demonstrating the need.
