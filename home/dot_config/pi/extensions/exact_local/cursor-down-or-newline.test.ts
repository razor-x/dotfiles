import type { KeybindingsManager } from '@earendil-works/pi-coding-agent'
import type { EditorTheme, TUI } from '@earendil-works/pi-tui'
import { describe, expect, it, vi } from 'vitest'
import { LocalEditor } from './cursor-down-or-newline.ts'

describe('LocalEditor', () => {
  it('moves the cursor down when it is not on the last visual line', () => {
    const requestRender = vi.fn()
    const moveCursor = vi.fn()
    const keybindings = {
      getUserBindings: () => ({
        'local.editor.cursorDownOrNewLine': 'down',
      }),
    } as unknown as KeybindingsManager
    const editor = new LocalEditor(
      { requestRender } as unknown as TUI,
      { borderColor: (text) => text } as EditorTheme,
      keybindings,
    )

    Object.assign(editor, {
      isOnLastVisualLine: () => false,
      moveCursor,
    })
    editor.handleInput('\x1b[B')

    expect(moveCursor).toHaveBeenCalledWith(1, 0)
    expect(requestRender).toHaveBeenCalledOnce()
  })
})
