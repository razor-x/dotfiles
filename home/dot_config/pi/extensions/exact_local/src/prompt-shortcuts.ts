import type { ExtensionAPI } from '@earendil-works/pi-coding-agent'

export const promptShortcuts = {
  continue: 'Continue.',
  'try-again': 'Try again.',
}

export function shortcutPrompt(prompt: string, args: string): string {
  const input = args.trim()

  return input === '' ? prompt : `${prompt}\n\n${input}`
}

export default function promptShortcutCommands(pi: ExtensionAPI): void {
  for (const [command, prompt] of Object.entries(promptShortcuts)) {
    pi.registerCommand(command, {
      description: `Send “${prompt}” to the agent`,
      handler: async (args) => pi.sendUserMessage(shortcutPrompt(prompt, args)),
    })
  }
}
