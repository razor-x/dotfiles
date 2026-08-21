import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionContext,
  type ExtensionHandler,
  type ExtensionUIContext,
  type KeybindingsManager,
  type SessionStartEvent,
} from '@earendil-works/pi-coding-agent'
import type { EditorTheme, KeyId, TUI } from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import cursorDownOrNewLine, { LocalEditor } from '@/cursor-down-or-newline.ts'

describe('cursorDownOrNewLine', () => {
  it('installs the editor in TUI mode', () => {
    const setEditorComponent = vi.fn()
    const handler = registerExtension()

    handler(
      fromPartial<SessionStartEvent>({}),
      fromPartial<ExtensionContext>({
        mode: 'tui',
        ui: fromPartial<ExtensionUIContext>({ setEditorComponent }),
      }),
    )

    expect(setEditorComponent).toHaveBeenCalledOnce()
    expect(setEditorComponent).toHaveBeenCalledWith(expect.any(Function))
  })

  it('does not install the editor outside TUI mode', () => {
    const setEditorComponent = vi.fn()
    const handler = registerExtension()

    handler(
      fromPartial<SessionStartEvent>({}),
      fromPartial<ExtensionContext>({
        mode: 'rpc',
        ui: fromPartial<ExtensionUIContext>({ setEditorComponent }),
      }),
    )

    expect(setEditorComponent).not.toHaveBeenCalled()
  })
})

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

  it.each([
    ['local.editor.thinkingLower', 'down', -1],
    ['local.editor.thinkingHigher', 'up', 1],
  ] as const)('handles the configured %s action', (action, key, offset) => {
    const selectThinkingLevel = vi.fn()
    const { editor } = createEditor(
      undefined,
      { [action]: key },
      selectThinkingLevel,
    )
    const parentHandleInput = mockParentHandleInput()

    editor.handleInput(key === 'down' ? '\x1b[B' : '\x1b[A')

    expect(selectThinkingLevel).toHaveBeenCalledWith(offset)
    expect(parentHandleInput).not.toHaveBeenCalled()
  })
})

function registerExtension(): ExtensionHandler<SessionStartEvent> {
  const on = vi.fn()
  cursorDownOrNewLine(fromPartial<ExtensionAPI>({ on }))
  expect(on).toHaveBeenCalledOnce()
  expect(on).toHaveBeenCalledWith('session_start', expect.any(Function))
  return fromPartial<ExtensionHandler<SessionStartEvent>>(on.mock.calls[0]?.[1])
}

function createEditor(
  binding: KeyId | KeyId[] | undefined,
  otherBindings: Record<string, KeyId> = {},
  selectThinkingLevel: (offset: -1 | 1) => void = () => undefined,
) {
  const requestRender = vi.fn()
  const moveCursor = vi.fn()
  const isOnLastVisualLine = vi.fn(() => false)
  const userBindings = {
    ...otherBindings,
    ...(binding ? { 'local.editor.cursorDownOrNewLine': binding } : {}),
  }
  const keybindings = fromPartial<KeybindingsManager>({
    getUserBindings: () => userBindings,
  })
  const editor = new LocalEditor(
    fromPartial<TUI>({ requestRender }),
    fromPartial<EditorTheme>({ borderColor: (text: string) => text }),
    keybindings,
    selectThinkingLevel,
  )

  Object.assign(editor, { isOnLastVisualLine, moveCursor })

  return { editor, isOnLastVisualLine, moveCursor, requestRender }
}

function mockParentHandleInput() {
  return vi
    .spyOn(CustomEditor.prototype, 'handleInput')
    .mockImplementation(() => undefined)
}
