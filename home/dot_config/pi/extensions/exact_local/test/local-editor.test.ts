import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionHandler,
  ExtensionUIContext,
  SessionStartEvent,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it, vi } from 'vitest'
import localEditor from '@/local-editor.ts'

describe('localEditor', () => {
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

function registerExtension(): ExtensionHandler<SessionStartEvent> {
  const on = vi.fn()
  localEditor(fromPartial<ExtensionAPI>({ on }))
  expect(on).toHaveBeenCalledOnce()
  expect(on).toHaveBeenCalledWith('session_start', expect.any(Function))
  return fromPartial<ExtensionHandler<SessionStartEvent>>(on.mock.calls[0]?.[1])
}
