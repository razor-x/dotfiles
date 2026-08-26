import type { KeybindingsManager } from '@earendil-works/pi-coding-agent'
import { matchesBinding } from './lib/keybinding.ts'
import type { EditorInputHandler } from './local-editor.ts'

const action = 'local.editor.cursorDownOrNewLine'

export function cursorDownOrNewLineInputHandler(
  keybindings: KeybindingsManager,
): EditorInputHandler {
  return (editor, data) => {
    if (!matchesBinding(data, keybindings, action)) {
      return false
    }

    if (editor.isAutocompleteVisible()) {
      editor.handleDefaultInput(data)
    } else if (editor.isOnLastVisualLineLocal()) {
      editor.handleDefaultInput('\n')
    } else {
      editor.moveCursorBy(1, 0)
      editor.requestRender()
    }
    return true
  }
}
