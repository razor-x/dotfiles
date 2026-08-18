# Agents: Kitty Remote-Control Security Boundary

Status: blocking companion security specification\
Applies to: MVP and all deferred agent features\
Depends on: `agents-design.md` and `agents-testing-strategy.md`\
Implementation homes: `razor-x/dotfiles/local/agents`, Kitty configuration,
and host Pi-launcher compatibility (`pi-nono` in these dotfiles)

## 1. Purpose

The agents extension needs to observe, create, focus, retitle, and close Kitty
tabs. Pi may itself run beneath an outer confinement layer; these dotfiles use
`pi-nono`, but nono is not part of the extension. Exposing Kitty's general
remote-control socket to such a Pi process would turn Kitty into a confused
deputy:

1. an arbitrary process in the Pi sandbox sends `launch`, `run`, `send-text`,
   or another powerful Kitty remote-control request;
1. the request reaches the Kitty process outside nono;
1. Kitty starts or controls a process with the user's host authority; and
1. the resulting process does not inherit the caller's nono restrictions.

At the time of this review, the risk is not directly exploitable because nono
blocks the configured abstract Kitty socket. `kitten @ ls` from the Pi sandbox
fails at `connect(2)` with `operation not permitted`. The existing Kitty setting
`allow_remote_control socket-only` would, however, accept every command
unconditionally if that socket became reachable. Merely granting socket access
to implement the planned Kitty adapter would therefore create a sandbox escape.

Executable Kitty restoration files create a second form of the same problem. A
file written under the Pi-writable agents state root cannot later be loaded by
Kitty as trusted session or configuration syntax. Escaping values while
initially rendering the file does not protect against replacement of the whole
file by another process in the sandbox.

This specification defines a narrow Kitty gateway that preserves agents
functionality without exposing general remote control. It also separates three
layers that must not be collapsed:

- the extension requests semantic agent lifecycle operations;
- trusted Kitty configuration selects the host Pi launcher; and
- the host Pi launcher applies any outer compatibility/confinement layer before
  it starts Pi.

For these dotfiles, the trusted launcher is the existing `pi-nono` command. The
extension neither constructs `nono run` nor owns the nono profile. Its central
security invariant is:

> Data controlled by a Pi process may cause Kitty to launch only a fixed,
> host-configured Pi launcher with host-authorized cwd and semantic Pi
> arguments. It may never select a host executable, shell command, sandbox
> grant, Kitty program, or executable Kitty configuration.

Kitty integration is blocked until this specification's acceptance gate passes.
Filesystem-only increments of the agents extension may proceed meanwhile.

## 2. Precedence and impact on the document suite

This document is normative wherever agent behavior crosses the Pi-to-Kitty
trust seam and wherever a Kitty-created Pi process must preserve an outer
confinement layer. If it conflicts with the MVP or a deferred feature
specification, this document wins.

In particular, it supersedes these earlier design details:

- direct use of standard `kitten @` commands by the extension;
- direct `kitten @ launch --type=tab` as an acceptable spike;
- launching bare `pi --session <path>` through Kitty;
- rendering and loading Pi-writable `.kitty-session` restoration files; and
- treating a Kitty restoration recipe as an owned agent resource.

It does not change managed-agent identity, Worktrunk ownership, Pi-session
semantics, operation journals, reconciliation, or the at-most-one-live-tab
invariant. It changes the Kitty adapter and the way a new Pi process is
activated.

Before Kitty integration is considered complete, the MVP specification must be
brought into line with Section 15. Until then, implementers must follow this
document rather than the superseded examples.

## 3. Threat model

### 3.1 Attacker capabilities

Assume an attacker can do all of the following from inside any Pi sandbox:

- execute arbitrary native code and scripts allowed by that sandbox;
- invoke `kitten`, implement the Kitty wire protocol directly, and send
  arbitrary bytes to every socket the sandbox can reach;
- read the process environment inherited by Pi and its children;
- read and modify the agents registry, operation journals, caches, plans, Pi
  sessions, generated files, and repository contents exposed by the nono
  profile;
- forge agent records, UUIDs, paths, titles, prompts, and adapter requests;
- race, replay, duplicate, reorder, or interrupt requests;
- invoke the same executables used by the extension without going through the
  extension's TypeScript interface; and
- exploit shell parsing, option parsing, symlink traversal, path aliasing,
  environment inheritance, and writable configuration if any such route is
  exposed.

The extension process and its writable files are therefore orchestration state,
not a host authorization authority. A Pi confirmation dialog remains useful UX,
but it does not distinguish the extension from another process in the same
sandbox.

### 3.2 Trusted computing base

The security design may trust only:

- the active outer confinement mechanism, when one is configured;
- the installed host Pi launcher and its outer-layer policy (`pi-nono` and the
  promoted `pi` nono profile in these dotfiles);
- the Kitty process and the installed Kitty configuration it loaded;
- the installed Kitty authorization and gateway modules, when those paths are
  not writable from a Pi sandbox;
- a small gateway policy store outside every Pi filesystem grant;
- fixed absolute paths to installed executables recorded in that policy; and
- an explicit confirmation rendered by trusted gateway code in a Kitty-owned
  overlay.

Agent records may provide requested values, but the gateway must independently
validate them against trusted policy and current Kitty state.

### 3.3 Security objectives

A compromised Pi sandbox must not be able to:

- start an unsandboxed host process through Kitty;
- broaden a new Pi process's filesystem or socket grants beyond a previously
  authorized repository policy;
- select arbitrary executable paths, arguments, environment variables, Kitty
  commands, kittens, session files, or configuration files;
- inject commands into an existing terminal;
- read arbitrary unmanaged terminal contents, command lines, or environments;
- replace a data file and have Kitty interpret it as executable syntax;
- connect to unrelated pathname or abstract UNIX sockets as a side effect of
  enabling agents; or
- silently create or close tabs when the gateway operation requires trusted
  confirmation.

### 3.4 Explicitly residual risks

Code in the sandbox can invoke every non-interactive operation intentionally
exposed by the narrow gateway. Those operations are limited to filtered
observation, adoption of a selected tab, managed title/activity updates, and
focus. Abuse may cause focus stealing or misleading cosmetic state, but it must
not provide host execution, terminal-content disclosure, or broader filesystem
access.

Creating a new process and closing a live managed tab require a Kitty-owned
confirmation. Repository authorization also requires such confirmation. An
attacker may display or spam confirmation requests, but cannot approve them.

An operator who deliberately approves Kitty's generic unknown-password remote
control prompt, runs an unsandboxed shell command, changes the trusted gateway
or launcher policy, or installs attacker-modified Kitty configuration has
explicitly crossed this security boundary. Compromise of Kitty, the configured
outer confinement layer, or the kernel is outside this specification.

## 4. Settled architecture

Kitty itself is the privileged broker. No additional resident daemon is added.
A custom Kitty gateway is the only remote-control capability exposed to Pi:

```text
Pi and repository processes
(optionally inside an outer sandbox such as nono)
  |
  | narrowly mediated access to one pathname UNIX socket
  | blank-password request for one fixed custom kitten entrypoint
  v
Kitty password dispatcher
  |
  | custom authorization: command + complete payload validation
  v
Pi Agents Kitty Gateway (trusted Kitty configuration)
  |  filtered observation
  |  identity-based tab operations
  |  trusted confirmation for process creation/closure
  |  fixed host-launcher selection and semantic Pi argv construction
  v
Kitty
  |
  | only agent process-creation route
  v
Configured HostPiLauncher
(dotfiles default: ~/.local/bin/pi-nono -> nono -> pi)
```

### 4.1 Why passwords and command-name rules are insufficient

A password available to the extension is also available to arbitrary code in
the same sandbox. It cannot identify the extension. A command-name rule that
allows `launch` still permits caller-selected programs and arguments, while
rules for `ls` or `get-text` may expose unrelated terminal state. Kitty socket
requests also have no trustworthy originating-window identity, so per-window
password rules do not constrain this socket path.

The design therefore uses the no-password route as an explicit low-authority
capability and places authorization in server-side operation and payload
validation. The gateway generates powerful Kitty commands internally; the Pi
caller can neither name nor parameterize them generically.

### 4.2 Deep gateway module

The extension sees one deep module at the Kitty seam:

```ts
type KittyGatewayRequest =
  | ObserveManagedTabsRequest
  | AdoptCurrentTabRequest
  | SetActivityRequest
  | FocusManagedTabRequest
  | AuthorizeRepositoryRequest
  | EnsureAgentPresentRequest
  | EnsureAgentAbsentRequest;

interface KittyGateway {
  execute(request: KittyGatewayRequest): Promise<KittyGatewayResult>;
}
```

Neither the interface nor any domain effect contains a Kitty command name,
executable, argv array, environment map, match expression, session-recipe path,
or arbitrary protocol payload. The production adapter serializes the typed
request. Tests use a fake adapter at the same seam.

The trusted gateway implementation may have private seams for policy storage,
Kitty control, launch construction, and confirmation UI. Those seams are not
part of the extension interface.

### 4.3 Configuration ownership

The extension may expose only an opaque compatibility preference, for example:

```ts
export const agentsConfig = {
  kitty: {
    launcherProfileId: "default",
  },
};
```

That value lets the extension request and diagnose the expected host setup; it
is not executable configuration and does not name nono. In these dotfiles the
Kitty gateway resolves `default` to its trusted `pi-nono` launcher profile and
pins that profile when the repository is authorized. An attacker who edits
extension config can request an unknown or different profile, but cannot alter
the executable or bypass a new trusted confirmation.

The fixed command may live directly in Kitty-side gateway configuration or in a
static user-owned Kitty template. In these dotfiles it resolves to the installed
`$HOME/.local/bin/pi-nono`, never the corresponding dotfiles source path. The
wrapper remains the sole owner of nono command construction and policy
compatibility.

## 5. Normative requirements

| ID    | Requirement                                                                                                                                                                                                                                              |
| ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| KR-01 | General Kitty remote control shall remain inaccessible to every confined Pi process.                                                                                                                                                                     |
| KR-02 | The nono compatibility path shall retain nono's isolation of parent-created abstract UNIX sockets.                                                                                                                                                       |
| KR-03 | When an outer layer mediates sockets, the host Pi launcher shall grant only connect access to the exact pathname socket for the current Kitty instance; it shall grant no bind or directory-write access.                                                |
| KR-04 | The agents socket shall live in a dedicated user-only runtime directory outside `/tmp` and outside every Pi-writable tree.                                                                                                                               |
| KR-05 | Kitty shall use `allow_remote_control password`; `socket-only`, `socket`, and `yes` are incompatible with this design because they accept socket requests unconditionally.                                                                               |
| KR-06 | The no-password Kitty rule exposed to Pi shall invoke one custom authorizer and shall default to denial for every command and payload.                                                                                                                   |
| KR-07 | The authorizer shall accept only the `kitten` remote command targeting one of the fixed installed gateway entrypoints with a bounded, closed-schema request envelope.                                                                                    |
| KR-08 | The authorizer shall reject direct `launch`, `run`, `send-text`, `load-config`, `action`, arbitrary `kitten`, and every other standard Kitty command.                                                                                                    |
| KR-09 | Authorization shall validate the complete payload and fail closed on unknown fields, unsupported versions, malformed encodings, control characters, oversized values, TTY-originated requests, streaming requests, or caller-selected match expressions. |
| KR-10 | The gateway shall expose typed agent operations rather than Kitty command pass-through.                                                                                                                                                                  |
| KR-11 | Gateway observation shall return only managed UUID, bounded display state, and match cardinality; it shall not return unmanaged tabs, screen text, shell command lines, or environment values.                                                           |
| KR-12 | Tab lookup and mutation shall resolve the `pi_managed_agent` UUID inside Kitty and shall refuse duplicate matches. Numeric Kitty IDs are transient request context and shall never become durable identity.                                              |
| KR-13 | Any request that would create a process or close a live managed tab shall execute only after a trusted Kitty-owned confirmation, unless it is an idempotent no-op discovered by the gateway.                                                             |
| KR-14 | Repository enrollment or expansion of an authorized worktree/session root shall require a trusted Kitty-owned confirmation and a durable host-side policy update.                                                                                        |
| KR-15 | The gateway shall never trust the agents registry, operation journal, cache, generated file, repository, or Pi session as authorization evidence.                                                                                                        |
| KR-16 | The only agent program Kitty may start is the fixed host Pi launcher selected by trusted Kitty-side configuration. These dotfiles select the installed `pi-nono` command.                                                                                |
| KR-17 | The gateway shall construct launcher-profile selection, semantic Pi arguments, cwd, environment, and Kitty options internally. No request field may supply an executable, generic argv, environment map, shell text, or outer-layer option.              |
| KR-18 | The gateway shall canonicalize and authorize dynamic paths before invoking the host launcher. The launcher—not the extension or gateway request—owns construction and enforcement of any outer sandbox grants.                                           |
| KR-19 | A requested worktree shall be a non-primary worktree within an authorized worktree root and shall link to the authorized Git common directory.                                                                                                           |
| KR-20 | A resume request shall use an existing regular Pi-session file inside an authorized Pi-session root. A bootstrap request shall not accept a caller-selected session path.                                                                                |
| KR-21 | Agent launches shall omit Kitty per-window `--allow-remote-control`, `--copy-env`, `--copy-cmdline`, stdin-copy, shell, and background-process features.                                                                                                 |
| KR-22 | Full-control Kitty passwords, `KITTY_RC_PASSWORD`, `KITTY_PUBLIC_KEY`, loader variables, and unrelated host credentials shall not enter an agent launch environment.                                                                                     |
| KR-23 | The extension shall send the gateway request without a password and shall never possess a full-control Kitty password.                                                                                                                                   |
| KR-24 | Restoration shall derive a typed `EnsureAgentPresentRequest` from agent data. Kitty shall never load a Pi-writable session/configuration file.                                                                                                           |
| KR-25 | Gateway and authorization code, policy state, and full-control password files shall be outside all Pi read/write grants; gateway code shall also be non-writable by group or other users.                                                                |
| KR-26 | Missing gateway code, unavailable socket mediation, policy mismatch, failed confirmation, or validation uncertainty shall disable the relevant Kitty operation without a permissive fallback.                                                            |
| KR-27 | The gateway shall bound request size, batch size, confirmation concurrency, and launch rate.                                                                                                                                                             |
| KR-28 | Security decisions and confirmed mutations shall produce a bounded host-side audit record containing no password, prompt body, terminal content, or credential.                                                                                          |
| KR-29 | Automated tests shall exercise the gateway with hostile payloads and prove exact generated launch arguments. Manual acceptance shall attempt the concrete escape paths listed in Section 12.3.                                                           |
| KR-30 | Kitty integration shall not ship until every acceptance-gate item in Section 14 passes on the installed Kitty, gateway, host-launcher, and active outer-layer versions.                                                                                  |
| KR-31 | A trusted confirmation process shall use a fixed neutral cwd, isolated imports, and a minimal fixed environment; repository modules, startup hooks, and interpreter environment variables shall not affect it.                                           |
| KR-32 | Trusted confirmation UI shall render every untrusted value with a non-interpreting escaping/quoting function and shall reject terminal controls, line breaks, bidirectional controls, and other spoofing characters.                                     |
| KR-33 | A sandbox-preserving host-launcher profile shall disable capability elevation and contain no broad home, runtime-socket, gateway-policy, or Kitty-credential grant that bypasses this design.                                                            |
| KR-34 | Extension configuration may request only an opaque launcher-profile ID. Executable/fixed arguments or template path/bytes shall come exclusively from trusted Kitty-side configuration.                                                                  |
| KR-35 | A launcher profile may be stored as host-owned Kitty configuration or a static Kitty-owned template, but no Pi-writable or per-agent generated file may choose the command or become executable Kitty syntax.                                            |
| KR-36 | A deployment that relies on an outer confinement layer shall use a launcher profile that preserves that layer. A plain-Pi launcher is compatible only when host policy explicitly declares that no outer confinement must be preserved.                  |
| KR-37 | If a launcher profile uses Kitty session syntax, only the gateway may render it into a Kitty-owned path using closed typed placeholders and context-correct escaping; Pi shall control neither template bytes, output bytes, nor template/output paths.  |
| KR-38 | Launcher, authorizer, gateway, and template paths shall resolve to installed runtime artifacts outside Pi write grants, never to a dotfiles source path or repository worktree.                                                                          |
| KR-39 | Bootstrap launch requests shall contain no task prompt, sender claim, or model-selected `parentAgentId`; delegation and assignment are handled after registration by the authenticated communication layer.                                                  |

## 6. Socket and password confinement

### 6.1 Pathname socket

Replace the abstract listener with a PID-qualified pathname in a dedicated
runtime directory, conceptually:

```text
$XDG_RUNTIME_DIR/pi-agents-kitty/kitty-{kitty_pid}.sock
```

The parent directory is created by trusted login/configuration code with mode
`0700`. The socket is owned by the current user and is not placed under `/tmp`,
the repository, `$XDG_STATE_HOME/pi-agents`, or another path recursively
writable by Pi.

Socket access belongs to the host-launcher compatibility layer, not the agents
extension. For these dotfiles, the existing `pi-nono` wrapper is extended to
validate `KITTY_LISTEN_ON` before entering nono:

- scheme is `unix:`;
- the canonical parent is the dedicated runtime directory;
- the basename matches the configured PID-qualified form;
- the path is a socket owned by the current UID; and
- the path is not a symlink.

Only then may `pi-nono` pass the path through nono's exact
`--allow-unix-socket` connect grant. It must not convert a caller-selected
`KITTY_LISTEN_ON` into a generic socket grant. A child launched by Kitty invokes
`pi-nono` with the validated cwd and semantic Pi arguments; `pi-nono` applies
the same compatibility policy before Pi starts.

The compatible Linux nono profile enables pathname AF_UNIX mediation and
separately inventories any other pathname sockets Pi genuinely needs. It does
not grant the runtime directory recursively and does not relax abstract-socket
scope. Another host launcher may implement different confinement, but it must
satisfy the same narrow-socket outcome. A platform or launcher that cannot do so
fails preflight rather than asking the extension to weaken the policy.

### 6.2 Kitty authorization mode

The effective Kitty configuration has this shape:

```conf
allow_remote_control password
listen_on unix:${XDG_RUNTIME_DIR}/pi-agents-kitty/kitty-{kitty_pid}.sock
remote_control_password "" pi-agents/rc_auth.py
```

`rc_auth.py` is the default-deny authorizer for requests without a password. It
requires `from_socket` and accepts only an exact invocation of the installed
Pi Agents gateway. The production client explicitly uses
`--use-password=never` so it cannot accidentally discover a password file or
environment variable.

Other trusted local Kitty integrations may use separate named passwords with
the minimum command set they require. A full-control password, if retained for
interactive host use, lives outside the dotfiles source and every Pi grant. The
host Pi launcher removes `KITTY_RC_PASSWORD` and `KITTY_PUBLIC_KEY` before
applying its outer layer and starting Pi. Agent tabs are launched without
per-window remote control.

Kitty may display its own prompt for an unknown nonblank password. That prompt
is not part of agents and is never accepted automatically. The absence of
`KITTY_PUBLIC_KEY` from Pi reduces that route but is defense in depth rather
than the core authorization control.

### 6.3 Fixed gateway entrypoints

Install a small trusted package under the runtime Kitty configuration, for
example:

```text
<kitty-config>/pi-agents/
  rc_auth.py
  control.py
  confirm.py
  gateway.py
```

- `control.py` is a no-UI entrypoint for filtered observation, current-tab
  adoption, bounded lifecycle titles, and focus.
- `confirm.py` renders a trusted overlay for repository authorization, process
  creation, and tab closure; its result handler revalidates and executes the
  request only after an explicit affirmative response. The UI process uses a
  fixed neutral cwd, isolated imports, and a minimal environment rather than
  the target window's repository cwd or environment.
- `gateway.py` owns parsing, policy, validation, identity resolution, launch
  construction, result normalization, and audit behavior shared by both
  entrypoints.
- `rc_auth.py` permits only these exact installed entrypoint names. A request
  cannot select another built-in or filesystem kitten.

The request is one bounded base64url-encoded canonical JSON argument. The
authorizer checks the command shape and envelope bounds before invocation; the
gateway independently decodes and validates the complete discriminated union.
Both layers default to denial.

## 7. Gateway protocol

### 7.1 Envelope and result

Every request contains only:

```ts
type GatewayEnvelope = {
  version: 1;
  requestId: string;
  controllerWindowId: number;
  operation: GatewayOperation;
};
```

`controllerWindowId` supplies only the transient Kitty window over which the
fixed kitten runs. The adapter emits the outer match as exactly
`id:<controllerWindowId>`, and the authorizer rejects an empty match, `all`,
regular expressions, and any mismatch with the envelope. The ID grants no
additional authority and is never persisted.

`requestId` supports audit correlation and duplicate suppression; it grants no
authority. The gateway rejects unknown fields and places conservative limits on
encoded bytes, strings, arrays, and batch size.

Every result is one bounded JSON value:

```ts
type GatewayResult =
  | { ok: true; requestId: string; outcome: GatewayOutcome }
  | {
      ok: false;
      requestId: string;
      code: GatewayErrorCode;
      message: string;
      retryable: boolean;
    };
```

Errors expose no terminal contents, host credentials, unrestricted paths, or
Python traceback. Internal details go only to the host-side audit/log channel.

### 7.2 Capability-safe control operations

The no-UI entrypoint supports:

- `observeManagedTabs(agentIds)`: resolve only requested well-formed UUIDs and
  return zero, one, or duplicate cardinality plus bounded gateway-derived
  title/activity state;
- `adoptCurrentTab(agentId, name)`: tag only the envelope's explicitly selected
  controller window after validating its transient numeric ID and safe display
  fields;
- `setActivity(agentId, name, activity)`: derive a title from an enum and safe
  display name, then update exactly one UUID-matched tab; and
- `focusManagedTab(agentId)`: focus exactly one UUID-matched tab.

These operations accept no raw match expressions, title templates, ANSI/control
sequences, Kitty actions, or arbitrary user variables. Names are length-bounded
Unicode display text with C0/C1 controls and escape characters rejected.

`adoptCurrentTab` cannot prove socket origin from Kitty window identity; Kitty
socket requests have no associated source window. It therefore treats the
numeric target as untrusted transient input and performs only the limited tag
and title operation. It does not launch, read, signal, or send text to the
window.

### 7.3 Confirmed mutation operations

The interactive entrypoint supports:

- `authorizeRepository(policyCandidate)`;
- `ensureAgentPresent(launchRequest)`; and
- `ensureAgentAbsent(agentId)`.

The trusted overlay shows the operation, UUID/name, canonical repository and
worktree, resume session identity when applicable, and the fixed host launcher
profile that will start Pi. In these dotfiles that profile is `pi-nono`. It
escapes and quotes all untrusted display values and rejects terminal,
line-break, bidirectional, and other spoofing controls before rendering. The
default answer is denial. There is no “remember all requests” choice.

The gateway revalidates after confirmation. `ensureAgentPresent` then performs
one atomic Kitty-side reconcile-and-act step:

1. more than one UUID match: refuse;
1. exactly one match: optionally focus and return `already-present` without
   launching or prompting;
1. no match: validate policy and launch exactly once.

`ensureAgentAbsent` similarly resolves by UUID, treats absence as an idempotent
no-op, refuses duplicates, and confirms before closing the sole matching tab.
It never sends text or shell exit commands. Graceful Pi shutdown may be added
only through a separately designed, confinement-preserving Pi mechanism; it is
not implemented as terminal input injection.

A bounded batch request may use one trusted confirmation when the overlay shows
every item and the gateway executes the exact confirmed immutable list
sequentially.

## 8. Host-authorized repository policy

The gateway keeps a small security policy separate from agent ownership state,
for example:

```ts
type HostPiLauncherProfileV1 = {
  schemaVersion: 1;
  launcherProfileId: string;
  launch:
    | {
        kind: "argv";
        executable: string;
        fixedArgs: readonly string[];
      }
    | {
        kind: "kitty-session-template";
        templatePath: string;
      };
  preservesOuterConfinement: boolean;
};

type AuthorizedRepositoryV1 = {
  schemaVersion: 1;
  authorizedRepositoryId: string;
  primaryWorktree: string;
  gitCommonDir: string;
  worktreeRoots: readonly string[];
  piSessionRoots: readonly string[];
  launcherProfileId: string;
  authorizedAt: string;
};
```

The launcher profiles live in trusted Kitty-side configuration. For these
dotfiles, the default profile selects the installed
`$HOME/.local/bin/pi-nono`, either directly or through a static Kitty-owned
session template, uses no caller-controlled prefix arguments, and marks outer
confinement as preserved. The extension may request an opaque profile ID during
repository enrollment, but the confirmed repository policy pins the result.
Editing extension state cannot change the launch definition.

This is not a second agent registry. It records only the host paths and launcher
profile that a Kitty-created Pi process may use. It contains no branch, agent,
parent, tab, PR, lifecycle, or resource ownership state.

The store lives under a Kitty-owned state directory such as:

```text
$XDG_STATE_HOME/kitty/pi-agents/
  authorized-repositories.json
  audit.jsonl
```

Pi receives no read or write grant to that directory. The gateway writes mode
`0600` temporary siblings, flushes them, and atomically renames them. Unknown
schema versions fail closed.

Repository enrollment is explicit. The extension may propose paths discovered
through Git and Worktrunk, but trusted gateway code canonicalizes them, displays
them, and stores them only after user confirmation. Expanding a root repeats the
same process. Revocation is a host-side Kitty operation, not an agent-record
edit.

For each launch, the gateway independently proves:

- policy ID exists;
- canonical worktree is beneath one authorized worktree root and is not the
  primary worktree;
- no path component used for authorization is an unresolved symlink;
- the worktree's Git link resolves into the authorized common directory;
- resume session is a regular file beneath an authorized Pi-session root;
- the pinned launcher profile exists and its executable/fixed arguments or
  static template path/bytes come only from trusted Kitty-side configuration;
- a policy that requires preserved outer confinement references a profile that
  declares and passes the corresponding compatibility checks; and
- the requested repository identity agrees with policy after canonicalization.

Agent state can request a launch, but changing that state cannot authorize a new
host root, launcher profile, or executable.

## 9. Host Pi launcher and confinement compatibility

### 9.1 Fixed launcher construction

The gateway generates Kitty launch options and the configured host-launcher
argv internally. The shape for these dotfiles is conceptually:

```text
Kitty launch
  type: tab
  cwd: <validated authorized worktree>
  user var: pi_managed_agent=<validated UUID>
  env: PI_MANAGED_AGENT_ID=<validated UUID>
  command:
    $HOME/.local/bin/pi-nono
      <internally constructed Pi resume/bootstrap arguments>
```

`pi-nono` remains responsible for resolving the Git common directory, invoking
`nono run --profile pi`, adding the compatible cwd/common-directory/socket
grants, and finally starting Pi. None of those nono details belong to the
extension or the Kitty gateway request.

The concrete argument order follows the host launcher's documented interface:
it accepts ordinary Pi CLI arguments as direct argv values and applies its
outer layer before forwarding them to Pi. Contract tests cover that interface.
The request never contains an executable, fixed launcher prefix, nono option,
sandbox grant, or generic Pi option.

Kitty starts the configured host launcher, not a shell. A deployment without an
outer sandbox may define a trusted profile for a direct Pi launcher, but that is
an explicit host policy choice and never a fallback from `pi-nono`. A deployment
that relies on nono or another outer layer refuses process creation unless its
pinned profile preserves that layer.

A launcher profile may be represented by ordinary Kitty-side data or by a
static user-owned Kitty template. In either form, the executable and fixed
prefix are host-owned literals. Dynamic agent values remain separately
validated argv elements; the gateway never writes a rendered executable
session file into Pi-owned state.

### 9.2 Environment

The gateway starts from a fixed minimal environment policy. It sets only the
small set needed by the configured host launcher, Pi, the terminal, and managed
identity. In particular it:

- does not use Kitty `--copy-env` or caller-provided environment values;
- removes `KITTY_RC_PASSWORD` and `KITTY_PUBLIC_KEY`;
- removes dynamic-loader and interpreter-injection variables;
- does not import repository `.env` files or shell startup output; and
- leaves only `KITTY_LISTEN_ON` for the exact safe gateway socket.

Any additional variable requires a named field, independent validation, a
security review, and a test proving it cannot alter the host launcher or its
outer-layer policy before confinement is applied.

### 9.3 Bootstrap and resume

A bootstrap launch receives only a validated managed-agent UUID and bounded
display name as dynamic agent data. It receives no task prompt,
`parentAgentId`, or asserted sender. The host launcher applies its configured outer
layer, starts interactive Pi, and the new Pi process creates and reports its
session through the normal agents lifecycle. After registration, the separate
authenticated communication layer may deliver an assignment through Pi's
message API. For these dotfiles the launch sequence is `pi-nono` to nono to Pi.

A resume launch receives an exact existing Pi-session path validated against
host policy. The gateway passes Pi's documented `--session <exact-path>` form
to the configured host launcher, which forwards it after applying any outer
layer.

No launch loads a Pi-writable Kitty session file. The preferred implementation
uses gateway-generated Kitty launch options directly. If the launcher profile
uses a static Kitty session template, only the trusted gateway may render and
load it, both source and output stay under Kitty-owned paths outside Pi grants,
and dynamic values use closed typed placeholders with Kitty-syntax escaping.

### 9.4 Same-tab promotion

Same-tab promotion creates no host process through Kitty. When Pi is running
under an outer confinement layer, the extension must prove the target is
already writable under the current capability set before switching runtime into
the new worktree. The standard Worktrunk configuration places managed
worktrees beneath the repository root already granted by `pi-nono`, so this
normally succeeds.

If the target lies outside current outer-layer grants, the running process
cannot broaden its own access. Promotion refuses or offers a confirmed gateway
launch through the configured host launcher into a fresh correctly confined
tab; it never weakens the current process to preserve same-tab behavior.

## 10. Restoration model

A managed agent no longer owns a `kitty-restore-definition` resource and the
agents state root contains no `.kitty-session` files. Worktree, Pi-session, and
agent UUID resources already contain the data needed to request restoration.

Restore follows this path:

1. the extension reconciles the durable agent and derives a typed
   `EnsureAgentPresentRequest`;
1. the gateway treats every supplied field as untrusted;
1. the gateway resolves the host-authorized repository policy and current
   Kitty UUID cardinality;
1. if absent, it confirms the canonical launch with the user;
1. it selects the pinned host launcher and constructs semantic Pi arguments
   internally; and
1. it returns a normalized launched/already-present/refused/uncertain result.

A user-owned template may select the fixed host launcher and format bounded
title text. The extension handles only its opaque profile ID. If the gateway
renders Kitty syntax, the source and result are Kitty-owned and inaccessible to
Pi; neither Kitty nor the gateway loads a sandbox-writable file. Restoration
therefore remains semantic without an extension-owned executable recipe.

## 11. Failure and recovery behavior

Security validation fails closed and remains distinct from ordinary external
failure:

- unavailable or denied socket: Kitty state is `unknown`; no fallback transport;
- authorization/gateway version mismatch: refuse with an upgrade/configuration
  error;
- missing repository policy: offer trusted enrollment, not implicit creation;
- path mismatch or symlink uncertainty: refuse before confirmation;
- canceled confirmation: no effect and no durable agent-resource transition;
- response lost after launch: record an uncertain effect, observe by UUID, and
  refuse a second launch until cardinality is known;
- duplicate UUID tabs: report broken state and refuse focus/close/launch
  mutation;
- Kitty restart: an old confined process cannot broaden its socket access; a
  Pi started through the host launcher obtains access to the new PID-qualified
  endpoint and reconstructs tab truth while repository authorization survives
  in host policy; and
- gateway audit failure: mutation fails before effect unless the audit record's
  post-effect uncertainty is explicitly represented and recoverable.

The extension never responds to gateway failure by invoking `kitten @` directly,
loading a session file, bypassing the configured host Pi launcher, broadening a
socket grant, or asking a shell to perform the operation.

## 12. Testing strategy

### 12.1 Pure and contract tests

Keep request derivation and result handling in TypeScript pure functions. Test
the production `KittyGateway` adapter with a fake command runner and captured
protocol fixtures. Assertions cover exact entrypoint, `--use-password=never`,
envelope encoding, result parsing, timeouts, malformed output, and absence of
raw Kitty command/argv fields from the interface.

Keep gateway parsing, repository policy checks, path containment, title
sanitization, launch construction, and result normalization independent of a
live Kitty `Boss`. Test those through the gateway's operation interface with a
fake internal Kitty adapter. The trusted Python authorizer receives a table of
complete `pcmd` fixtures.

Hostile tables include:

- every standard Kitty remote-control command;
- alternate kitten names, absolute/relative path aliases, and attempts to use
  dotfiles source/worktree paths instead of installed runtime artifacts;
- extra payload keys, unexpected protocol flags, streams, and `no_response`;
- malformed/base64 bombs, oversized JSON, duplicate keys, and unsupported
  versions;
- UUID, title/name, and path terminal controls, line breaks, bidirectional
  controls, zero-width spoofing characters, and invalid Unicode;
- rejected bootstrap keys for prompts, `parentAgentId`, sender claims, and
  option-looking names;
- `..`, symlinks, hard links where relevant, path-prefix confusion, alternate
  separators, deleted/recreated paths, and worktrees linked to another common
  directory;
- forged agent records, repository policies, and launcher-profile IDs;
- arbitrary executable, fixed launcher arguments, Kitty template path/bytes,
  env, cwd, session, outer-layer option, and sandbox-grant attempts;
- replayed request IDs and concurrent ensure-present calls;
- a repository cwd containing modules that shadow gateway, standard-library,
  or Kitty imports and hostile interpreter startup environment; and
- zero, one, and duplicate matching tabs.

Tests assert the exact generated Kitty and host-launcher argument arrays. The
dotfiles compatibility tests separately assert that `pi-nono` turns the
validated cwd/socket and semantic Pi arguments into the intended nono command.
A test fails if any caller-controlled string can occupy an executable, fixed
launcher prefix, outer-layer option, Kitty command, match expression,
environment-variable name, or configuration path.

### 12.2 Installed-policy checks

Add a deterministic security check that inspects rendered configuration and
proves:

- effective Kitty mode is `password`;
- the listener is a pathname under the dedicated runtime directory;
- the blank-password rule points only to the custom authorizer;
- gateway/auth files are outside Pi grants;
- the trusted Kitty-side launcher profile selects `pi-nono` for this deployment;
- `pi-nono` grants only the validated exact socket;
- compatible pathname AF_UNIX mediation is enabled;
- compatible abstract-socket isolation remains enabled;
- no full-control Kitty password enters Pi's environment; and
- no agents code or state path produces `.kitty-session` files.

### 12.3 Live adversarial acceptance

Run these checks in a disposable Kitty instance and disposable repository:

1. From Pi's nono sandbox, confirm direct `kitten @ ls`, `launch`, `run`,
   `send-text`, `load-config`, `close-tab`, and an arbitrary custom kitten are
   denied.
1. Confirm direct protocol messages equivalent to those commands are denied;
   renaming or replacing the `kitten` executable must not matter.
1. Confirm the gateway returns only requested managed UUID state and reveals no
   unmanaged tab title, cwd, command line, environment, or screen text.
1. Modify every Pi-writable agent/session/restoration path and confirm Kitty
   executes none of it.
1. Request `/bin/sh`, `/usr/bin/env`, another launcher profile, fixed-prefix
   arguments, a different nono profile, `--allow $HOME`,
   `/var/run/docker.sock`, an out-of-policy cwd, and an out-of-policy session;
   confirm all are rejected before launch.
1. Launch a legitimate child and prove it cannot read a canary outside its
   authorized repository/session grants or connect to an unrelated UNIX socket.
1. Confirm the child's process was created through the configured `pi-nono`
   launcher and that a failed outer-layer setup leaves no Pi process or tab
   reported as successfully active.
1. Confirm spawn, restore, close, and repository expansion require the trusted
   gateway overlay and that cancel performs no effect.
1. Race two ensure-present requests and confirm at most one UUID-tagged tab.
1. Restart Kitty, reconnect only to its new exact pathname socket, and restore
   the exact Pi session through the same gateway.
1. Confirm the existing unsandboxed smart-splits and user Kitty workflows use
   separate least-privilege credentials and that those credentials are absent
   inside Pi.

Record Kitty, gateway, `pi-nono`, Pi, and nono versions with the acceptance
result because custom-kitten, launcher, and socket-mediation behavior are
version-sensitive.

## 13. Implementation plan

### Phase 0: preserve the current block

- Keep the abstract Kitty socket inaccessible to Pi.
- Do not add an abstract-socket scope exception or broad pathname-socket grant.
- Keep Kitty adapter production mutations disabled while filesystem-only agents
  increments proceed.

Complete when a test from the current Pi sandbox still gets `EPERM` for direct
Kitty socket access and no agents code has a permissive fallback.

### Phase 1: build the deny-by-default gateway offline

- Define the closed TypeScript request/result union.
- Implement the Kitty authorizer and fixed `control.py`/`confirm.py`
  entrypoints.
- Put parsing, validation, launch construction, and result normalization behind
  the deep gateway interface.
- Add fake-Kitty and hostile-payload tests before exposing a socket.

Complete when every non-gateway command and every malformed gateway payload is
denied in tests, while valid requests produce only normalized fake effects.

### Phase 2: migrate Kitty and host-launcher socket compatibility

- Replace the abstract listener with the dedicated PID-qualified pathname.
- Change Kitty to password authorization.
- Update the dotfiles-owned `pi-nono` launcher to validate and grant only the
  exact current socket; keep this logic outside the extension.
- Enable explicit pathname AF_UNIX mediation in the compatible nono profile and
  inventory other required sockets.
- Separate existing user/smart-splits credentials and scrub them in the host Pi
  launcher.

Complete when Pi can call only the fixed gateway entrypoints and the direct
adversarial commands in Section 12.3 remain denied.

### Phase 3: add host repository authorization

- Implement the separate atomic gateway policy store and audit log.
- Add the trusted repository-enrollment overlay.
- Define trusted Kitty-side host-launcher profiles, selecting `pi-nono` as the
  dotfiles default.
- Validate canonical worktree roots, Git common-directory linkage, Pi-session
  roots, installed-runtime launcher/template identity, fixed executable/prefix,
  and confinement compatibility.

Complete when forged extension state cannot authorize a new root, launcher,
executable, fixed argument, template path/bytes, or socket and policy expansion
always requires trusted confirmation.

### Phase 4: activate observation and cosmetic control

- Implement filtered observe, adopt, activity-title, and focus operations.
- Replace raw Kitty topology parsing in the extension with normalized gateway
  results.
- Add UUID duplicate refusal and bounded rate behavior.

Complete when the extension can reconcile and focus managed tabs without
receiving information about unmanaged tabs or access to a standard Kitty
command.

### Phase 5: activate compatible spawn, restore, and stop

- Implement confirmed ensure-present and ensure-absent operations.
- Construct the exact host-launcher/Pi argv internally and verify that the
  dotfiles profile executes fresh-child and resume flows through `pi-nono`.
- Treat lost responses as uncertain and reconcile before retry.

Complete when child spawn, exact-session restore, and idempotent stop work while
all host-command, grant-injection, environment-injection, and duplicate-launch
acceptance tests fail closed.

### Phase 6: remove executable restoration artifacts

- Remove `kitty-restore-definition` from the resource union and operation plans.
- Remove the `kitty/` per-agent session-file state directory and executable
  restoration-template configuration; retain only trusted static host-launcher
  configuration.
- Derive restore requests from worktree, Pi-session, UUID, and trusted host
  policy.
- Update archive, cleanup, testing, and dependency documents accordingly.

Complete when no Pi-controlled runtime path writes or loads Kitty session
syntax and deleting an agent has no extension-owned restoration-definition
cleanup action. A trusted gateway-owned static launcher template remains
allowed under KR-35.

## 14. Acceptance gate

Kitty integration is releasable only when all of the following are true:

1. The effective installed Kitty configuration uses password mode and the
   dedicated pathname socket.
1. The installed `pi-nono` compatibility path and nono policy disable
   capability elevation, grant only exact Kitty connect access, expose no
   gateway policy or credential, and retain abstract-socket isolation.
1. Direct standard Kitty commands and direct wire-protocol equivalents from Pi
   are denied.
1. The only accepted no-password command is a valid fixed gateway invocation.
1. The gateway's complete hostile request matrix passes.
1. Every Kitty-created Pi process starts through the repository's pinned host
   launcher; these dotfiles prove that launcher is `pi-nono` and that its
   resulting grants remain host-authorized and canonical.
1. Full-control Kitty credentials and executable gateway/policy state are
   inaccessible from Pi.
1. No sandbox-writable file is interpreted as Kitty configuration, a Kitty
   session, a command, or an argv array.
1. Managed observation reveals no unmanaged terminal data.
1. Spawn/restore/close and policy expansion have a trusted confirmation with
   isolated imports, a neutral cwd, escaped display values, and bounded
   replay/race behavior.
1. The live adversarial acceptance checklist passes on the installed Kitty,
   gateway, host-launcher, Pi, and active outer-layer versions.
1. The MVP, dependency, and testing specifications no longer direct an
   implementer toward bare Pi launch or executable restoration files.

A partial implementation may expose fewer Kitty operations. It may not relax
one of these controls to expose more.

## 15. Required amendments to existing specifications

When implementation reaches the corresponding phase, update the suite as one
change:

- `agents-design.md`
  - replace `kitty-restore-definition` with no additional durable resource;
  - remove `${stateRoot}/kitty/*.kitty-session`;
  - replace Section 15's direct RC/session-template design with the gateway;
  - change spawn and restore to typed ensure-present requests;
  - change stop/focus/adoption to gateway operations; and
  - replace per-agent executable Kitty template configuration with
    gateway/policy configuration and an opaque host-launcher profile.
- `agents-dependency-policy.md`
  - replace bare `pi --session` launch with the configured host Pi launcher
    (`pi-nono` in these dotfiles) through the gateway;
  - retain direct argument arrays and no-shell execution; and
  - recognize the Kitty authorization/gateway modules as local trusted code,
    not npm runtime dependencies.
- `agents-testing-strategy.md`
- `agents-delegation-communication.md`
  - make `KittyGateway.execute` the production/fake seam;
  - add authorizer, gateway validation, launch-construction, policy-store, and
    adversarial installed-policy tests; and
  - keep live Kitty UX in the manual security acceptance suite.
- Deferred archive, transactional-promotion, and multi-repository documents
  - remove restoration-definition lifecycle actions;
  - require each repository to have host gateway authorization; and
  - retain the same exact gateway for every scope.

## 16. References

- [Kitty remote control](https://sw.kovidgoyal.net/kitty/remote-control/)
- [Kitty remote-control protocol](https://sw.kovidgoyal.net/kitty/rc_protocol/)
- [Kitty custom kittens](https://sw.kovidgoyal.net/kitty/kittens/custom/)
- [Kitty discussion #5320: fine-grained remote-control permissions](https://github.com/kovidgoyal/kitty/discussions/5320)
- nono `run --help`: exact `--allow-unix-socket` connect grants
- nono profile guide: Linux `af_unix_mediation: "pathname"` and
  `filesystem.unix_socket`
