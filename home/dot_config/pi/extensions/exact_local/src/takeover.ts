import { existsSync } from 'node:fs'
import { hostname } from 'node:os'
import { basename } from 'node:path'
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import {
  listTakeoverOwners,
  requestTakeover,
  startTakeoverService,
  type TakeoverService,
} from './lib/takeover.ts'

const stateKey = Symbol.for('dotfiles.pi.takeover')
const processState = globalThis as typeof globalThis & {
  [stateKey]?: Promise<TakeoverService>
}

export default function takeover(pi: ExtensionAPI): void {
  pi.on('session_start', async (_event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    try {
      processState[stateKey] ??= startTakeoverService()
      const service = await processState[stateKey]
      service.bind(
        () => {
          const sessionFile = ctx.sessionManager.getSessionFile()
          if (!sessionFile || !existsSync(sessionFile)) {
            return undefined
          }
          return {
            sessionFile,
            name:
              ctx.sessionManager.getSessionName() ||
              basename(sessionFile, '.jsonl'),
          }
        },
        () => {
          ctx.ui.notify(
            'Session takeover requested; exiting after queued work and cleanup finish.',
            'info',
          )
          ctx.shutdown()
        },
      )
    } catch (error) {
      delete processState[stateKey]
      ctx.ui.notify(`Session takeover unavailable: ${String(error)}`, 'warning')
    }
  })

  pi.on('session_shutdown', async () => {
    // Process-scoped IPC must survive reloads and remain open until actual exit,
    // not merely until our shutdown handler (other extensions may still write).
    const service = await processState[stateKey]?.catch(() => undefined)
    service?.unbind()
  })

  pi.registerCommand('takeover', {
    description:
      'Take over an active session from another interactive Pi process',
    handler: async (_args, ctx) => {
      if (ctx.mode !== 'tui') {
        ctx.ui.notify('/takeover requires interactive mode.', 'warning')
        return
      }

      let sessionFile: string
      try {
        await ctx.waitForIdle()
        const owners = (await listTakeoverOwners()).filter(
          (owner) => owner.pid !== process.pid,
        )
        if (owners.length === 0) {
          ctx.ui.notify(
            'No active sessions found. The owner must have the takeover extension loaded.',
            'info',
          )
          return
        }

        const labels = owners.map(
          (owner) => `${owner.name} — PID ${owner.pid} on ${hostname()}`,
        )
        const choice = await ctx.ui.select(
          'Take over an active session',
          labels,
        )
        const selected = owners.find(
          (_owner, index) => labels[index] === choice,
        )
        if (!selected) {
          return
        }
        const confirmed = await ctx.ui.select(
          `Take over ${selected.name} from PID ${selected.pid}? It will finish queued work and exit.`,
          ['Yes, take over', 'No'],
        )
        if (confirmed !== 'Yes, take over') {
          return
        }

        const currentOwners = await listTakeoverOwners()
        if (
          currentOwners.filter(
            (owner) => owner.sessionFile === selected.sessionFile,
          ).length !== 1
        ) {
          throw new Error(
            'Session has no owner or multiple owners. Refusing takeover; check the other Pi windows.',
          )
        }
        ctx.ui.notify(
          'Waiting up to 5 minutes for the owner to finish and exit. It will not be force-killed.',
          'info',
        )
        await requestTakeover(selected)
        sessionFile = selected.sessionFile
      } catch (error) {
        ctx.ui.notify(`Takeover failed: ${String(error)}`, 'error')
        return
      }
      // shortcut: this command coordinates only cooperating interactive owners;
      // universal pre-open locking needs Pi core support.
      await ctx.switchSession(sessionFile)
    },
  })
}
