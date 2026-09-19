import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { Type } from 'typebox'

export default function reloadRuntime(pi: ExtensionAPI): void {
  let reloadPending = false
  let continuation: ReturnType<typeof setImmediate> | undefined

  pi.on('session_start', (event, ctx) => {
    if (event.reason !== 'reload') {
      return
    }

    const entry = ctx.sessionManager.getBranch().at(-1)
    if (
      entry?.type !== 'message' ||
      entry.message.role !== 'toolResult' ||
      entry.message.toolName !== 'reload_runtime' ||
      entry.message.isError
    ) {
      return
    }

    const { toolCallId } = entry.message
    continuation = setImmediate(() => {
      continuation = undefined
      pi.appendEntry('runtime-reload-resumed', { toolCallId })
      pi.sendMessage(
        {
          customType: 'runtime-reloaded',
          content:
            'Runtime reloaded successfully. Continue the current task. For a UI change, run just request-pi-ui and inspect the returned PNG before reporting completion. Do not reload again unless another source change requires it.',
          display: false,
        },
        { triggerTurn: true, deliverAs: 'followUp' },
      )
    })
  })

  pi.on('session_shutdown', () => {
    clearImmediate(continuation)
    continuation = undefined
  })

  pi.registerCommand('reload-runtime', {
    description: 'Reload Pi runtime resources',
    handler: async (_args, ctx) => {
      await ctx.reload()
    },
  })

  pi.on('agent_settled', () => {
    if (!reloadPending) {
      return
    }

    reloadPending = false
    pi.sendUserMessage('/reload-runtime', { expandPromptTemplates: true })
  })

  pi.registerTool({
    name: 'reload_runtime',
    label: 'Reload Runtime',
    description: 'Sync Pi dotfiles and reload the runtime',
    parameters: Type.Object({}),
    async execute(_toolCallId, _params, signal) {
      const result = await pi.exec('pi-sync-dotfiles', [], { signal })
      if (result.code !== 0) {
        throw new Error(result.stderr || result.stdout)
      }

      reloadPending = true
      return {
        content: [
          {
            type: 'text',
            text: 'Synced dotfiles; reload pending response completion.',
          },
        ],
        details: {},
        terminate: true,
      }
    },
  })
}
