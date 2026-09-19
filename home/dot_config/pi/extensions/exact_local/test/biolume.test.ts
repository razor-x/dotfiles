import { stripVTControlCharacters } from 'node:util'
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ExtensionEvent,
  ExtensionHandler,
  Theme,
  WorkingIndicatorOptions,
} from '@earendil-works/pi-coding-agent'
import { type Component, type TUI, visibleWidth } from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import biolume from '@/biolume.ts'
import { ListeningSigil, sigil } from '@/biolume-sigil.ts'

afterEach(() => vi.useRealTimers())

describe('listening sigil', () => {
  it('makes stable, fixed-width fingerprints and holds its shape during typing bursts', () => {
    expect(sigil('hello')).toBe(sigil(' hello\n'))
    expect(sigil('hello')).not.toBe(sigil('goodbye'))
    expect(sigil('caf\u00e9')).toBe(sigil('cafe\u0301'))
    expect(visibleWidth(sigil('路径 🪸'))).toBe(3)
    const listener = new ListeningSigil()
    listener.observe('h', 0)
    const first = listener.display(0, false).glyph
    listener.observe('he', 50)
    expect(listener.display(50, false).glyph).toBe(first)
    expect(listener.display(800, false)).toEqual({
      glyph: `  ${sigil('he')}  `,
      label: '',
    })
  })

  it('reacts locally to draft changes, settles, then stamps the same mark on submission', async () => {
    vi.useFakeTimers()
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const widget = app.widget()
    widget.render(80)
    expect(vi.getTimerCount()).toBe(0)
    app.draft('Make it listen')
    expect(widget.render(80)).toHaveLength(1)
    expect(widget.render(80).join()).not.toContain('listening')
    expect(vi.getTimerCount()).toBe(1)
    vi.advanceTimersByTime(810)
    const settled = widget.render(80).map(stripVTControlCharacters).join('')
    expect(settled).toContain(sigil('Make it listen'))
    expect(settled).not.toContain('listening')
    expect(vi.getTimerCount()).toBe(0)
    await app.emit({
      type: 'input',
      text: 'Make it listen',
      source: 'interactive',
    })
    app.draft('')
    expect(widget.render(80).map(stripVTControlCharacters).join()).toContain(
      sigil('Make it listen'),
    )
    const context = {
      messageType: 'user' as const,
      isStreaming: false,
      availableWidth: 80,
    }
    expect(app.transform('Make it listen', context)).toBe(
      `\`${sigil('Make it listen')}\`\n\nMake it listen`,
    )
    expect(
      app.transform('answer', { ...context, messageType: 'assistant' }),
    ).toBe('answer')
    for (const width of [0, 1, 5, 12, 80]) {
      expect(
        widget.render(width).every((line) => visibleWidth(line) <= width),
      ).toBe(true)
    }
    await app.command('off', app.ctx)
    expect(app.transform('Make it listen', context)).toBe('Make it listen')
  })

  it('uses one activity row with the glyph instead of Working and hides only thinking labels', async () => {
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const widget = app.widget()
    await app.emit({ type: 'input', text: 'hello', source: 'interactive' })
    await app.emit({ type: 'agent_start' })
    expect(widget.render(80)).toEqual([])
    expect(app.ctx.ui.setWorkingMessage).toHaveBeenLastCalledWith(
      app.ctx.ui.theme.fg('accent', `  ${sigil('hello')}  `),
    )
    expect(app.ctx.ui.setHiddenThinkingLabel).toHaveBeenLastCalledWith('')
    const calls = vi.mocked(app.ctx.ui.setWorkingMessage).mock.calls.length
    widget.render(80)
    expect(app.ctx.ui.setWorkingMessage).toHaveBeenCalledTimes(calls)
    await app.emit({ type: 'agent_settled' })
    expect(widget.render(80)).toHaveLength(1)
    await app.command('off', app.ctx)
    expect(app.ctx.ui.setWorkingMessage).toHaveBeenLastCalledWith()
    expect(app.ctx.ui.setHiddenThinkingLabel).toHaveBeenLastCalledWith()
  })

  it('keeps the original spore pulse and stops all motion in still/off/shutdown', async () => {
    vi.useFakeTimers()
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const widget = app.widget()
    expect(app.indicator()?.frames?.map(stripVTControlCharacters)).toEqual([
      '  ·  ',
      '  •  ',
      ' ·●· ',
      ' •◉• ',
      ' ·◎· ',
      '  ○  ',
      '  ·  ',
      '  ·  ',
    ])
    app.draft('typing')
    widget.render(80)
    expect(vi.getTimerCount()).toBe(1)
    await app.command('still', app.ctx)
    expect(vi.getTimerCount()).toBe(0)
    expect(app.indicator()?.frames).toHaveLength(1)
    expect(widget.render(80).join()).not.toContain('listening')
    await app.command('on', app.ctx)
    app.draft('typing more')
    widget.render(80)
    await app.emit({ type: 'session_shutdown', reason: 'reload' })
    expect(vi.getTimerCount()).toBe(0)
    expect(app.ctx.ui.theme).toBe(app.original)
    expect(app.indicator()).toBeUndefined()
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
  const setWorkingIndicator =
    vi.fn<(options?: WorkingIndicatorOptions) => void>()
  const ctx = fromPartial<ExtensionCommandContext>({
    mode,
    sessionManager: { getBranch: () => [] },
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
      setWorkingIndicator,
      setWorkingVisible: vi.fn(),
      setWorkingMessage: vi.fn(),
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
    draft: (text: string) => getEditorText.mockReturnValue(text),
    indicator: () => setWorkingIndicator.mock.lastCall?.[0],
    command: fromPartial<
      Parameters<ExtensionAPI['registerCommand']>[1]['handler']
    >(registerCommand.mock.calls[0]?.[1].handler),
    transform: fromPartial<
      Parameters<ExtensionAPI['registerMarkdownTransformer']>[0]
    >(registerMarkdownTransformer.mock.calls[0]?.[0]),
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
