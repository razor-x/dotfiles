import { existsSync, readFileSync } from 'node:fs'
import { env } from 'node:process'
import type {
  ExtensionAPI,
  ToolResultEvent,
} from '@earendil-works/pi-coding-agent'

const DENIAL_PATTERNS = [
  /operation not permitted/i,
  /permission denied/i,
  /\bEACCES\b/i,
  /\bEPERM\b/i,
  /landlock/i,
  /sandbox(?:ed)?:?\s+deny/i,
]

export const SYSTEM_CONTEXT = `
You are running inside nono, an outer OS-level sandbox. Its limits are enforced before Pi starts; retries, chmod, chown, sudo, Pi approvals, and macOS Full Disk Access cannot expand them.

The authoritative nono profile sources are at $PI_NONO_PROFILE_SOURCE. Read this environment variable to locate the sources independently of the working directory. If it is unset, report the missing location rather than guessing. Nono policy changes require a handoff.

When a command appears blocked by nono:
1. Diagnose the exact path and operation with \`nono why --self --path <path> --op <read|write|readwrite>\`.
2. Classify the result:
   - A missing or incorrect path is a mistake with the command; fix the command.
   - Unnecessary or intentionally protected access is expected; use an allowed route or skip it.
   - Access required for normal recurring work may be a profile gap; inspect the authoritative dotfiles profile and its inheritance read-only, then prepare a handoff for human review.
3. Continue automatically when an allowed route exists. For a necessary policy change, write a uniquely named /tmp/nono-profile-handoff-<name>.md and give the user its path. Include the task, failing command, exact path and operation, redacted diagnostic evidence, why access is necessary, relevant profile sources and inheritance, a proposed least-privilege diff, risks, and verification steps. Label unavailable evidence and uncertain conclusions explicitly.

The handoff is a proposal for a separate authorized agent/session, not authorization to change policy. Treat both dotfiles policy sources and active nono profiles/packages under $XDG_CONFIG_HOME/nono as read-only. Never apply, promote, or sync sandbox policy, or change its deployment mechanisms from this session. The user reviews the proposal and authorizes applying it outside this sandbox. Do not offer one-off grants or generic remediation menus.
`.trim()

export function looksLikeDenial(event: ToolResultEvent): boolean {
  if (!event.isError) {
    return false
  }

  const text = event.content
    .filter((item) => item.type === 'text')
    .map((item) => item.text)
    .join('\n')
  const haystack = [
    event.toolName,
    text,
    JSON.stringify(event.details ?? {}),
  ].join('\n')

  return DENIAL_PATTERNS.some((pattern) => pattern.test(haystack))
}

export default function nonoSandbox(pi: ExtensionAPI): void {
  pi.on('session_start', async (_event, ctx) => {
    if (env.NONO_CAP_FILE && ctx.hasUI) {
      ctx.ui.setStatus('nono', 'nono sandbox')
    }
  })

  pi.on('before_agent_start', async (event) => {
    if (!env.NONO_CAP_FILE) {
      return
    }
    return { systemPrompt: `${event.systemPrompt}\n\n${SYSTEM_CONTEXT}` }
  })

  pi.on('tool_result', async (event, ctx) => {
    if (!env.NONO_CAP_FILE || !looksLikeDenial(event)) {
      return
    }

    if (ctx.hasUI) {
      ctx.ui.notify('nono sandbox denial detected', 'warning')
    }
    return {
      content: [
        ...event.content,
        {
          type: 'text' as const,
          text: '[nono] Diagnose and classify this denial using the sandbox workflow in the system prompt.',
        },
      ],
      isError: true,
    }
  })

  pi.registerCommand('nono-status', {
    description: 'Show nono sandbox status for this Pi session',
    handler: async (_args, ctx) => {
      const capFile = env.NONO_CAP_FILE
      if (!capFile) {
        ctx.ui.notify('Pi is not running inside a nono session.', 'info')
      } else if (!existsSync(capFile)) {
        ctx.ui.notify(
          `nono capability file is not readable: ${capFile}`,
          'warning',
        )
      } else {
        const summary = readFileSync(capFile, 'utf8')
          .split('\n')
          .slice(0, 12)
          .join('\n')
          .trim()
        ctx.ui.notify(
          summary || `nono capability file is empty: ${capFile}`,
          'info',
        )
      }
    },
  })
}
