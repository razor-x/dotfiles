import { stripVTControlCharacters } from 'node:util'
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ExtensionEvent,
  ExtensionHandler,
  Theme,
} from '@earendil-works/pi-coding-agent'
import { type Component, type TUI, visibleWidth } from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import biolume from '@/biolume.ts'
import { LivingBody } from '@/biolume-body.ts'

afterEach(() => vi.useRealTimers())

describe('living body', () => {
  it('blooms the original spore inside the strand, restoring each cell as it travels', () => {
    const body = new LivingBody()
    const fg = vi.fn((_color: string, text: string) => text)
    const theme = fromPartial<Theme>({ fg })
    const idle = body.render(80, theme, 0, false)
    const cells = [...(idle[0]?.trim() ?? '')]
    expect(cells.length).toBeGreaterThan(10)
    expect(
      cells.every((cell) => ((cell.charCodeAt(0) - 0x2800) & 0x12) === 0x12),
    ).toBe(true)
    body.setWorking(true, 0)
    const colors = [
      'dim',
      'muted',
      'accent',
      'borderAccent',
      'thinkingHigh',
      'accent',
      'muted',
      'dim',
    ]
    const spores = ['·', '•', '●', '◉', '◎', '○', '·', '·']
    for (let step = 0; step <= 2 * (cells.length - 1); step++) {
      fg.mockClear()
      const head = step < cells.length ? step : 2 * (cells.length - 1) - step
      const expected = cells.map((cell, index) =>
        index === head ? spores[step % 8] : cell,
      )
      expect(body.render(80, theme, step * 240, false)).toEqual([
        ` ${expected.join('')}`,
      ])
      expect(fg.mock.calls[head]?.[0]).toBe(colors[step % 8])
    }
    body.observe('a pending draft', 0)
    fg.mockClear()
    body.render(80, theme, (cells.length - 1) * 240, false)
    expect(fg.mock.calls.at(-1)).toEqual([
      colors[(cells.length - 1) % 8],
      spores[(cells.length - 1) % 8],
    ])
    for (const width of [0, 1, 2, 5, 12, 80]) {
      expect(
        body
          .render(width, theme, 0, false)
          .every((line) => visibleWidth(line) <= width),
      ).toBe(true)
    }
  })

  it('reacts at the attached tip and settles without moving or stamping a second copy', async () => {
    vi.useFakeTimers()
    vi.setSystemTime(0)
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const widget = app.widget()
    const idle = widget.render(80)
    expect(vi.getTimerCount()).toBe(0)
    app.draft('Make it listen')
    const typing = widget.render(80)
    expect(typing).not.toEqual(idle)
    expect(typing.map(stripVTControlCharacters)).toEqual(
      idle.map(stripVTControlCharacters),
    )
    expect(vi.getTimerCount()).toBe(1)
    vi.advanceTimersByTime(810)
    widget.render(80)
    expect(vi.getTimerCount()).toBe(0)
    app.draft('')
    await app.emit({ type: 'agent_start' })
    expect(widget.render(80).map(stripVTControlCharacters)).toEqual(
      idle.map((line) => ` ·${stripVTControlCharacters(line).slice(2)}`),
    )
    expect(app.registerMarkdownTransformer).not.toHaveBeenCalled()
    expect(app.ctx.ui.setWorkingVisible).toHaveBeenLastCalledWith(false)
    expect(app.ctx.ui.setHiddenThinkingLabel).toHaveBeenLastCalledWith('')
    await app.emit({ type: 'agent_settled' })
    vi.advanceTimersByTime(810)
    expect(widget.render(80)).toEqual(idle)
    expect(vi.getTimerCount()).toBe(0)
  })

  it('stops motion in still/off/shutdown and restores native status', async () => {
    vi.useFakeTimers()
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const widget = app.widget()
    await app.emit({ type: 'agent_start' })
    widget.render(80)
    expect(vi.getTimerCount()).toBe(1)
    await app.command('still', app.ctx)
    expect(vi.getTimerCount()).toBe(0)
    const still = widget.render(80)
    vi.advanceTimersByTime(2000)
    expect(widget.render(80)).toEqual(still)
    await app.command('off', app.ctx)
    expect(app.ctx.ui.setWorkingVisible).toHaveBeenLastCalledWith(true)
    expect(app.ctx.ui.setHiddenThinkingLabel).toHaveBeenLastCalledWith()
    expect(app.ctx.ui.setWidget).toHaveBeenLastCalledWith('biolume', undefined)
    await app.command('on', app.ctx)
    app.widget().render(80)
    expect(vi.getTimerCount()).toBe(1)
    await app.emit({ type: 'session_shutdown', reason: 'reload' })
    expect(vi.getTimerCount()).toBe(0)
    expect(app.ctx.ui.theme).toBe(app.original)
  })

  it.each(['rpc', 'json', 'print'] as const)(
    'leaves %s untouched',
    async (mode) => {
      const app = setup(mode)
      await app.emit({ type: 'session_start', reason: 'startup' })
      await app.command('still', app.ctx)
      expect(app.ctx.ui.setTheme).not.toHaveBeenCalled()
      expect(app.ctx.ui.setWidget).not.toHaveBeenCalled()
    },
  )
})

function setup(mode: ExtensionContext['mode'] = 'tui') {
  const original = fromPartial<Theme>({
    name: 'dark',
    getColorMode: () => 'truecolor',
  })
  let currentTheme = original
  const requestRender = vi.fn()
  const setWidget = vi.fn()
  const getEditorText = vi.fn(() => '')
  const ctx = fromPartial<ExtensionCommandContext>({
    mode,
    ui: {
      get theme() {
        return currentTheme
      },
      getTheme: () => original,
      setTheme: vi.fn((theme) => {
        if (typeof theme !== 'string') {
          currentTheme = theme
        }
        return { success: true }
      }),
      setWidget,
      getEditorText,
      setWorkingVisible: vi.fn(),
      setHiddenThinkingLabel: vi.fn(),
      notify: vi.fn(),
    },
  })
  const on = vi.fn()
  const registerCommand = vi.fn()
  const registerMarkdownTransformer = vi.fn()
  biolume(
    fromPartial<ExtensionAPI>({
      on,
      registerCommand,
      registerMarkdownTransformer,
    }),
  )
  return {
    ctx,
    original,
    registerMarkdownTransformer,
    draft: (text: string) => getEditorText.mockReturnValue(text),
    command: fromPartial<
      Parameters<ExtensionAPI['registerCommand']>[1]['handler']
    >(registerCommand.mock.calls[0]?.[1].handler),
    emit: async (event: ExtensionEvent) => {
      const handler = fromPartial<ExtensionHandler<ExtensionEvent>>(
        on.mock.calls.find(([type]) => type === event.type)?.[1],
      )
      await handler(event, ctx)
    },
    widget: () => {
      const factory = fromPartial<(tui: TUI, theme: Theme) => Component>(
        setWidget.mock.lastCall?.[1],
      )
      return factory(fromPartial<TUI>({ requestRender }), currentTheme)
    },
  }
}
