import { stripVTControlCharacters } from 'node:util'
import {
  type ExtensionAPI,
  type ExtensionContext,
  type ExtensionEvent,
  type ExtensionHandler,
  FooterComponent,
  type KeybindingsManager,
  type Theme,
} from '@earendil-works/pi-coding-agent'
import {
  CURSOR_MARKER,
  type EditorTheme,
  type TUI,
  type TuiMouseEvent,
  visibleWidth,
} from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { LocalEditor } from '@/local-editor.ts'
import shellChrome from '@/shell-chrome.ts'

const theme = fromPartial<Theme>({
  fg: (_color: string, text: string) => `\x1b[36m${text}\x1b[39m`,
  bg: (_color: string, text: string) => `\x1b[48;5;235m${text}\x1b[49m`,
  getBgAnsi: () => '\x1b[48;5;235m',
})
afterEach(() => vi.restoreAllMocks())

describe('shell chrome', () => {
  it('frames native editor rows without losing text, scroll labels, or the hardware cursor', () => {
    const plain = editor()
    const framed = editor(theme)
    const text = Array.from({ length: 20 }, (_, i) => `${i}: 界 🪸 text`).join(
      '\n',
    )
    plain.setText(text)
    framed.setText(text)
    plain.focused = true
    framed.focused = true
    for (const width of [12, 30, 80]) {
      const original = plain.render(width - 4).map(stripVTControlCharacters)
      const result = framed.render(width)
      expect(
        result.map(stripVTControlCharacters).map((line) => line.slice(2, -2)),
      ).toEqual(original)
      expect(result.every((line) => visibleWidth(line) === width)).toBe(true)
      expect(result.join('')).toContain(CURSOR_MARKER)
      expect(result[0]).toContain('↑')
      expect(framed.getText()).toBe(text)
      expect(framed.getCursor()).toEqual(plain.getCursor())
    }
    expect(framed.render(10)).toEqual(plain.render(10))
  })

  it('maps mouse clicks to the same input cells inside the frame', () => {
    const framed = editor(theme)
    framed.setText('a界b')
    framed.render(30)
    framed.handleMouse(
      fromPartial<TuiMouseEvent>({
        type: 'click',
        button: 'left',
        x: 5,
        y: 1,
        width: 30,
        height: 3,
      }),
    )
    expect(framed.getCursor()).toEqual({ line: 0, col: 2 })
  })

  it('decorates the existing footer without replacing its data and restores it on shutdown', async () => {
    const original = vi
      .spyOn(FooterComponent.prototype, 'render')
      .mockReturnValue(['cwd (branch)', 'tokens / model', 'existing statuses'])
    const on = vi.fn()
    shellChrome(fromPartial<ExtensionAPI>({ on }))
    const ctx = fromPartial<ExtensionContext>({ mode: 'tui', ui: { theme } })
    const emit = async (event: ExtensionEvent) => {
      const handler = fromPartial<ExtensionHandler<ExtensionEvent>>(
        on.mock.calls.find(([type]) => type === event.type)?.[1],
      )
      await handler(event, ctx)
    }
    const footer = fromPartial<FooterComponent>({})
    await emit({ type: 'session_start', reason: 'startup' })
    await emit({ type: 'session_start', reason: 'resume' })
    const lines = FooterComponent.prototype.render.call(footer, 40)
    expect(original).toHaveBeenLastCalledWith(36)
    expect(lines).toHaveLength(4)
    expect(lines.every((line) => visibleWidth(line) === 40)).toBe(true)
    expect(
      lines
        .slice(0, -1)
        .map(stripVTControlCharacters)
        .map((line) => line.slice(2, -2).trimEnd()),
    ).toEqual(['cwd (branch)', 'tokens / model', 'existing statuses'])
    FooterComponent.prototype.render.call(footer, 10)
    expect(original).toHaveBeenLastCalledWith(10)
    await emit({ type: 'session_shutdown', reason: 'reload' })
    expect(FooterComponent.prototype.render).toBe(original)
    ctx.mode = 'rpc'
    await emit({ type: 'session_start', reason: 'startup' })
    expect(FooterComponent.prototype.render).toBe(original)
  })
})

function editor(chromeTheme?: Theme): LocalEditor {
  return new LocalEditor(
    fromPartial<TUI>({ requestRender: vi.fn(), terminal: { rows: 24 } }),
    fromPartial<EditorTheme>({ borderColor: (text: string) => text }),
    fromPartial<KeybindingsManager>({
      matches: () => false,
      getUserBindings: () => ({}),
    }),
    [],
    chromeTheme,
  )
}
