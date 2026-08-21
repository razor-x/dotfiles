import {
  copyToClipboard,
  type ExtensionUIContext,
} from '@earendil-works/pi-coding-agent'

export async function copyPrompt(
  text: string,
  ui: ExtensionUIContext,
  copy: (text: string) => Promise<void> = copyToClipboard,
): Promise<void> {
  try {
    await copy(text)
    ui.notify('Copied prompt to clipboard', 'info')
  } catch (error) {
    ui.notify(error instanceof Error ? error.message : String(error), 'error')
  }
}
