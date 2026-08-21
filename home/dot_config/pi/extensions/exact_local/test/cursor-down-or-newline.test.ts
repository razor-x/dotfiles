import {
  CustomEditor,
  type KeybindingsManager,
} from '@earendil-works/pi-coding-agent'
import type { EditorTheme, KeyId, TUI } from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { cursorDownOrNewLineInputHandler } from '@/cursor-down-or-newline.ts'
import { LocalEditor } from '@/local-editor.ts'

describe('LocalEditor', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('moves the cursor down when it is not on the last visual line', () => {
    const { editor, moveCursor, requestRender } = createEditor('down')
    const parentHandleInput = mockParentHandleInput()

    editor.handleInput('\x1b[B')

    expect(moveCursor).toHaveBeenCalledWith(1, 0)
    expect(requestRender).toHaveBeenCalledOnce()
    expect(parentHandleInput).not.toHaveBeenCalled()
  })

  it('inserts a newline when the cursor is on the last visual line', () => {
    const { editor, isOnLastVisualLine, moveCursor, requestRender } =
      createEditor('down')
    const parentHandleInput = mockParentHandleInput()
    isOnLastVisualLine.mockReturnValue(true)

    editor.handleInput('\x1b[B')

    expect(parentHandleInput).toHaveBeenCalledOnce()
    expect(parentHandleInput).toHaveBeenCalledWith('\n')
    expect(moveCursor).not.toHaveBeenCalled()
    expect(requestRender).not.toHaveBeenCalled()
  })

  it('delegates matching input while autocomplete is visible', () => {
    const { editor, isOnLastVisualLine, moveCursor, requestRender } =
      createEditor('down')
    const parentHandleInput = mockParentHandleInput()
    vi.spyOn(editor, 'isShowingAutocomplete').mockReturnValue(true)

    editor.handleInput('\x1b[B')

    expect(parentHandleInput).toHaveBeenCalledOnce()
    expect(parentHandleInput).toHaveBeenCalledWith('\x1b[B')
    expect(isOnLastVisualLine).not.toHaveBeenCalled()
    expect(moveCursor).not.toHaveBeenCalled()
    expect(requestRender).not.toHaveBeenCalled()
  })

  it.each([
    ['the action has no binding', undefined, '\x1b[B'],
    ['the input does not match the binding', 'down' as const, 'x'],
  ])('delegates input when %s', (_description, binding, input) => {
    const { editor, isOnLastVisualLine, moveCursor, requestRender } =
      createEditor(binding)
    const parentHandleInput = mockParentHandleInput()

    editor.handleInput(input)

    expect(parentHandleInput).toHaveBeenCalledOnce()
    expect(parentHandleInput).toHaveBeenCalledWith(input)
    expect(isOnLastVisualLine).not.toHaveBeenCalled()
    expect(moveCursor).not.toHaveBeenCalled()
    expect(requestRender).not.toHaveBeenCalled()
  })

  it('supports multiple bindings for the action', () => {
    const { editor, moveCursor, requestRender } = createEditor(['up', 'down'])
    const parentHandleInput = mockParentHandleInput()

    editor.handleInput('\x1b[A')

    expect(moveCursor).toHaveBeenCalledWith(1, 0)
    expect(requestRender).toHaveBeenCalledOnce()
    expect(parentHandleInput).not.toHaveBeenCalled()
  })
})

function createEditor(binding: KeyId | KeyId[] | undefined) {
  const requestRender = vi.fn()
  const moveCursor = vi.fn()
  const isOnLastVisualLine = vi.fn(() => false)
  const userBindings = binding
    ? { 'local.editor.cursorDownOrNewLine': binding }
    : {}
  const keybindings = fromPartial<KeybindingsManager>({
    getUserBindings: () => userBindings,
  })
  const editor = new LocalEditor(
    fromPartial<TUI>({ requestRender }),
    fromPartial<EditorTheme>({ borderColor: (text: string) => text }),
    keybindings,
    [cursorDownOrNewLineInputHandler(keybindings)],
  )

  Object.assign(editor, { isOnLastVisualLine, moveCursor })

  return { editor, isOnLastVisualLine, moveCursor, requestRender }
}

function mockParentHandleInput() {
  return vi
    .spyOn(CustomEditor.prototype, 'handleInput')
    .mockImplementation(() => undefined)
}
