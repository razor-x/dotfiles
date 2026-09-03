import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from '@earendil-works/pi-coding-agent'

export default function deleteCommand(pi: ExtensionAPI): void {
  pi.registerCommand('delete', {
    description: 'Go back one prompt',
    handler: async (_args, ctx) => deletePrompt(ctx),
  })
}

export async function deletePrompt(
  ctx: ExtensionCommandContext,
): Promise<void> {
  await ctx.waitForIdle()
  const prompt = [...ctx.sessionManager.getBranch()]
    .reverse()
    .find((entry) => entry.type === 'message' && entry.message.role === 'user')

  if (prompt == null) {
    ctx.ui.notify('No prompt to delete', 'warning')
    return
  }

  await ctx.navigateTree(prompt.id)
}
