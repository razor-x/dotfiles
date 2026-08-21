import { getSupportedThinkingLevels } from '@earendil-works/pi-ai'
import type {
  ExtensionAPI,
  ExtensionContext,
  KeybindingsManager,
} from '@earendil-works/pi-coding-agent'
import { matchesBinding } from './lib/keybinding.ts'
import type { EditorInputHandler } from './local-editor.ts'

const lowerAction = 'local.editor.thinkingLower'
const higherAction = 'local.editor.thinkingHigher'

export function thinkingInputHandler(
  keybindings: KeybindingsManager,
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): EditorInputHandler {
  return (_editor, data) => {
    if (matchesBinding(data, keybindings, lowerAction)) {
      selectThinkingLevel(pi, ctx, -1)
      return true
    }
    if (matchesBinding(data, keybindings, higherAction)) {
      selectThinkingLevel(pi, ctx, 1)
      return true
    }
    return false
  }
}

export function selectThinkingLevel(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  offset: -1 | 1,
): void {
  if (ctx.model == null) return
  const levels = getSupportedThinkingLevels(ctx.model)
  const index = levels.indexOf(pi.getThinkingLevel())
  pi.setThinkingLevel(levels[(index + offset + levels.length) % levels.length])
}
