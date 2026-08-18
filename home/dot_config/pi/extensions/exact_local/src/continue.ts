import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export default function continueCommand(pi: ExtensionAPI): void {
  pi.registerCommand('continue', {
    description: 'Tell the agent to continue',
    handler: async () => pi.sendUserMessage('Continue.'),
  })
}
