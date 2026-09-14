import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export function continuePrompt(args: string): string {
  const input = args.trim()

  return input === '' ? 'Continue.' : `Continue.\n\n${input}`
}

export default function continueCommand(pi: ExtensionAPI): void {
  pi.registerCommand('continue', {
    description: 'Tell the agent to continue',
    handler: async (args) => pi.sendUserMessage(continuePrompt(args)),
  })
}
