import { stripVTControlCharacters } from 'node:util'
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
  ExtensionEvent,
  ExtensionHandler,
  SessionEntry,
  Theme,
  WorkingIndicatorOptions,
} from '@earendil-works/pi-coding-agent'
import { type Component, type TUI, visibleWidth } from '@earendil-works/pi-tui'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import biolume from '@/biolume.ts'
import { Bloom, clean, renderBloom } from '@/biolume-bloom.ts'

afterEach(() => vi.useRealTimers())

describe('biolume', () => {
  it('animates only during work, stops for still/off/shutdown, and restores the theme', async () => {
    vi.useFakeTimers()
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    app.widget()
    expect(app.ctx.ui.theme.name).toBe('biolume')
    expect(app.ctx.ui.setWorkingVisible).toHaveBeenLastCalledWith(true)
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
    expect(app.indicator()?.intervalMs).toBe(240)
    expect(vi.getTimerCount()).toBe(0)
    await app.emit({ type: 'agent_start' })
    expect(vi.getTimerCount()).toBe(1)
    vi.advanceTimersByTime(480)
    expect(app.requestRender).toHaveBeenCalled()
    await app.command('still', app.ctx)
    expect(app.indicator()?.frames).toHaveLength(1)
    expect(vi.getTimerCount()).toBe(0)
    await app.command('on', app.ctx)
    expect(vi.getTimerCount()).toBe(1)
    await app.emit({ type: 'agent_settled' })
    expect(vi.getTimerCount()).toBe(0)
    await app.command('off', app.ctx)
    expect(app.ctx.ui.theme).toBe(app.original)
    expect(app.ctx.ui.setWorkingVisible).toHaveBeenLastCalledWith(true)
    expect(app.indicator()).toBeUndefined()
    expect(app.ctx.ui.setWorkingMessage).toHaveBeenLastCalledWith()
    await app.command('on', app.ctx)
    await app.emit({ type: 'agent_start' })
    await app.emit({ type: 'session_shutdown', reason: 'reload' })
    expect(vi.getTimerCount()).toBe(0)
    expect(app.ctx.ui.theme).toBe(app.original)
  })

  it('tracks parallel tools independently, restores branch history, and fits narrow widths', async () => {
    const app = setup()
    await app.emit({ type: 'session_start', reason: 'startup' })
    const bloom = new Bloom()
    bloom.start('a', 'read', { path: 'some/路径.ts' })
    bloom.start('b', 'edit', { path: 'a.ts' })
    bloom.finish('b', true)
    expect(bloom.nodes.map((node) => node.state)).toEqual(['running', 'failed'])
    bloom.settle()
    expect(bloom.nodes.map((node) => node.state)).toEqual([
      'interrupted',
      'failed',
    ])
    for (const width of [0, 1, 12, 28, 40, 79, 80, 120, 240]) {
      expect(
        renderBloom(bloom, width, app.ctx.ui.theme).every(
          (line) => visibleWidth(line) <= width,
        ),
      ).toBe(true)
    }
    const restored = fromPartial<SessionEntry[]>([
      {
        type: 'message',
        message: {
          role: 'assistant',
          content: [
            {
              type: 'toolCall',
              id: 'r',
              name: 'read',
              arguments: { path: 'restored.ts' },
            },
          ],
        },
      },
      {
        type: 'message',
        message: { role: 'toolResult', toolCallId: 'r', isError: false },
      },
    ])
    bloom.restore(restored)
    expect(bloom.nodes).toMatchObject([
      { id: 'r', state: 'done', label: 'restored.ts' },
    ])
    const rendered = renderBloom(bloom, 120, app.ctx.ui.theme)
      .map(stripVTControlCharacters)
      .join('\n')
    expect(rendered).toContain('○01')
    expect(rendered).toContain('restored.ts')
    expect(rendered).not.toContain('a.ts')
    await app.command('off', app.ctx)
  })

  it('keeps display data bounded and strips terminal controls from labels', () => {
    const bloom = new Bloom()
    for (let i = 0; i < 100; i++) {
      bloom.start(String(i), 'read', { path: `file${i}` })
    }
    bloom.start('99', 'read', { path: 'duplicate' })
    expect(bloom.nodes).toHaveLength(64)
    expect(bloom.nodes[0]?.label).toBe('file36')
    expect(clean('\x1b[31mred\x1b[0m\n\u202eraw')).toBe('red  raw')
  })

  it.each(['rpc', 'json', 'print'] as const)(
    'leaves %s untouched',
    async (mode) => {
      const app = setup(mode)
      await app.emit({ type: 'session_start', reason: 'startup' })
      await app.emit({ type: 'agent_start' })
      await app.command('still', app.ctx)
      await app.emit({ type: 'session_shutdown', reason: 'quit' })
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
      setWorkingVisible: vi.fn(),
      setWorkingIndicator,
      setWorkingMessage: vi.fn(),
      notify: vi.fn(),
    },
  })
  const on = vi.fn()
  const registerCommand = vi.fn()
  biolume(fromPartial<ExtensionAPI>({ on, registerCommand }))
  const command = fromPartial<
    Parameters<ExtensionAPI['registerCommand']>[1]['handler']
  >(
    registerCommand.mock.calls.find(([name]) => name === 'biolume')?.[1]
      .handler,
  )
  return {
    ctx,
    original,
    requestRender,
    command,
    indicator: () => setWorkingIndicator.mock.lastCall?.[0],
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
