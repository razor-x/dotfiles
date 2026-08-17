import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'
import type { AgentsService } from './application.ts'

export const createProvisioningAction = 'Create agent (provisioning only)'

export function registerAgentsCommand(
  pi: Pick<ExtensionAPI, 'registerCommand'>,
  agents: AgentsService,
): void {
  pi.registerCommand('agents', {
    description: 'Manage coding agents in the current repository',
    handler: async (args, ctx) => {
      await handleAgentsCommand(args, ctx, agents)
    },
  })
}

export async function handleAgentsCommand(
  args: string,
  ctx: ExtensionCommandContext,
  agents: AgentsService,
): Promise<void> {
  if (args.trim().length > 0) {
    ctx.ui.notify(
      'Usage: /agents (subcommands are not available in this increment)',
      'warning',
    )
    return
  }

  if (!ctx.hasUI) {
    ctx.ui.notify('/agents requires an interactive UI', 'error')
    return
  }

  const action = await ctx.ui.select('Agents', [createProvisioningAction])
  if (action !== createProvisioningAction) return

  const enteredName = await ctx.ui.input('Agent name')
  if (enteredName === undefined) return

  const name = enteredName.trim()
  if (name.length === 0) {
    ctx.ui.notify('Agent name must not be empty', 'warning')
    return
  }

  try {
    await ctx.waitForIdle()
    const result = await agents.beginPromotion({ cwd: ctx.cwd, name })
    ctx.ui.notify(
      [
        `Agent ${result.id} is provisioning.`,
        `State: ${result.stateFile}`,
        'No branch, worktree, Pi session, Kitty tab, observation cache, or GitHub resource was created.',
      ].join('\n'),
      'info',
    )
  } catch (error) {
    ctx.ui.notify(errorMessage(error), 'error')
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error)
}
