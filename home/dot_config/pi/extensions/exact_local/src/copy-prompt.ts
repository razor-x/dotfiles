import {
  copyToClipboard,
  type ExtensionUIContext,
  type KeybindingsManager,
} from '@earendil-works/pi-coding-agent'
import { matchesBinding } from './lib/keybinding.ts'
import type { EditorInputHandler } from './local-editor.ts'

const action = 'local.editor.copyPrompt'

export function copyPromptInputHandler(
  keybindings: KeybindingsManager,
  ui: ExtensionUIContext,
): EditorInputHandler {
  return (editor, data) => {
    if (!matchesBinding(data, keybindings, action)) {
      return false
    }
    void copyPrompt(editor.getText(), ui)
    return true
  }
}

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
