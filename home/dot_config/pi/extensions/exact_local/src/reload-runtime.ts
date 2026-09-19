import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'
import { Type } from 'typebox'

export default function reloadRuntime(pi: ExtensionAPI): void {
  let reloadPending = false

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
