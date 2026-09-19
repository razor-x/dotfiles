import {
  type ExtensionAPI,
  type ExtensionContext,
  Theme,
} from '@earendil-works/pi-coding-agent'
import { Bloom, nodeGlyph, renderBloom } from './biolume-bloom.ts'

export default function biolume(pi: ExtensionAPI): void {
  const bloom = new Bloom()
  let previousTheme: Theme | undefined
  let enabled = false
  let still = false
  let afterReload = false
  let timer: ReturnType<typeof setInterval> | undefined
  let requestRender: (() => void) | undefined

  const stop = () => {
    clearInterval(timer)
    timer = undefined
  }
  const update = () => {
    if (enabled && bloom.active && !still && bloom.phase !== 'waiting') {
      timer ??= setInterval(() => {
        bloom.frame = (bloom.frame + 1) % 120
        requestRender?.()
      }, 240)
    } else {
      stop()
    }
    requestRender?.()
  }
  const applyTheme = (ctx: ExtensionContext) => {
    if (ctx.ui.theme.name !== 'biolume') {
      // ui.theme is a live proxy; getTheme loads a snapshot.
      previousTheme = ctx.ui.getTheme(ctx.ui.theme.name ?? 'dark')
    }
    const result = ctx.ui.setTheme(createTheme(ctx.ui.theme.getColorMode()))
    if (!result.success) {
      ctx.ui.notify(`Biolume: ${result.error}`, 'error')
    }
  }
  const restore = (ctx: ExtensionContext) => {
    stop()
    if (ctx.mode !== 'tui' || !enabled) {
      return
    }
    enabled = false
    ctx.ui.setWidget('biolume', undefined)
    ctx.ui.setWorkingVisible(true)
    ctx.ui.setWorkingIndicator()
    ctx.ui.setWorkingMessage()
    if (ctx.ui.theme.name === 'biolume' && previousTheme) {
      ctx.ui.setTheme(previousTheme)
    }
  }
  const apply = (ctx: ExtensionContext) => {
    if (ctx.mode !== 'tui') {
      return
    }
    applyTheme(ctx)
    const theme = ctx.ui.theme
    ctx.ui.setWorkingMessage(theme.fg('toolTitle', 'Working'))
    ctx.ui.setWorkingIndicator({
      frames: still
        ? [theme.fg('accent', ' ·●· ')]
        : [
            theme.fg('dim', '  ·  '),
            theme.fg('muted', '  •  '),
            theme.fg('accent', ' ·●· '),
            theme.fg('borderAccent', ' •◉• '),
            theme.fg('thinkingHigh', ' ·◎· '),
            theme.fg('accent', '  ○  '),
            theme.fg('muted', '  ·  '),
            theme.fg('dim', '  ·  '),
          ],
      intervalMs: 240,
    })
    ctx.ui.setWorkingVisible(true)
    if (!enabled) {
      enabled = true
      ctx.ui.setWidget('biolume', (tui, theme) => {
        requestRender = () => tui.requestRender()
        return {
          render: (width) => renderBloom(bloom, width, theme),
          invalidate() {},
          dispose() {
            stop()
            requestRender = undefined
          },
        }
      })
    }
    update()
  }

  pi.on('session_start', (event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    bloom.restore(ctx.sessionManager.getBranch())
    afterReload = event.reason === 'reload'
    apply(ctx)
  })
  pi.on('session_tree', (_event, ctx) => {
    if (ctx.mode === 'tui') {
      bloom.restore(ctx.sessionManager.getBranch())
      update()
    }
  })
  pi.on('session_shutdown', (_event, ctx) => restore(ctx))
  pi.on('agent_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    // Pi 0.85.1 reapplies saved colors after session_start on reload.
    if (enabled && afterReload) {
      applyTheme(ctx)
      afterReload = false
    }
    bloom.active = true
    bloom.phase = 'forming'
    update()
  })
  pi.on('message_update', (event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    const type = event.assistantMessageEvent.type
    const phase =
      type === 'thinking_delta'
        ? 'thinking'
        : type === 'text_delta'
          ? 'replying'
          : bloom.phase
    if (phase !== bloom.phase) {
      bloom.phase = phase
      update()
    }
  })
  pi.on('tool_execution_start', (event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    bloom.start(event.toolCallId, event.toolName, event.args)
    bloom.phase = 'working'
    update()
  })
  pi.on('tool_execution_end', (event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    bloom.finish(event.toolCallId, event.isError)
    update()
  })
  pi.on('agent_settled', (_event, ctx) => {
    if (ctx.mode === 'tui') {
      bloom.settle()
      update()
    }
  })
  pi.on('ui_prompt_start', (_event, ctx) => {
    if (ctx.mode === 'tui') {
      bloom.phase = 'waiting'
      update()
    }
  })
  pi.on('ui_prompt_end', (_event, ctx) => {
    if (ctx.mode === 'tui') {
      bloom.phase = ctx.isIdle() ? 'resting' : 'forming'
      update()
    }
  })

  pi.registerCommand('biolume', {
    description:
      'Living activity trace: on, still (no motion), off; resets on reload',
    handler: async (args, ctx) => {
      switch (args.trim()) {
        case '':
        case 'on':
        case 'still':
          still = args.trim() === 'still'
          apply(ctx)
          break
        case 'off':
          restore(ctx)
          break
        default:
          ctx.ui.notify('Usage: /biolume [on|still|off]', 'warning')
      }
    },
  })
  pi.registerCommand('bloom', {
    description: 'Inspect the recent actions that formed the living trace',
    handler: async (_args, ctx) => {
      if (ctx.mode !== 'tui') {
        return
      }
      await ctx.ui.select(
        'Bloom · recent actions (view only; full results in transcript)',
        bloom.nodes
          .map(
            (node, i) =>
              `${i + 1} ${nodeGlyph(node)} ${node.tool} · ${node.state} · ${node.label}`,
          )
          .reverse(),
      )
    },
  })
}

function createTheme(mode: ConstructorParameters<typeof Theme>[2]): Theme {
  const pearl = '#dcf4ed'
  const mint = '#7ee7c5'
  const glow = '#b6ffe2'
  const violet = '#c4a7f5'
  const coral = '#ff8f9c'
  const amber = '#f2cd88'
  const muted = '#9ab8b2'
  const dim = '#71948c'
  const edge = '#395e58'

  return new Theme(
    {
      accent: mint,
      border: '#578e82',
      borderAccent: glow,
      borderMuted: edge,
      success: mint,
      error: coral,
      warning: amber,
      muted,
      dim,
      text: pearl,
      thinkingText: muted,
      scrollbarTrack: edge,
      scrollbarThumb: mint,
      searchMatchText: glow,
      userMessageText: pearl,
      customMessageText: pearl,
      customMessageLabel: violet,
      toolTitle: '#ff8700',
      toolOutput: '#bfd5cf',
      mdHeading: glow,
      mdLink: '#8cdbec',
      mdLinkUrl: muted,
      mdCode: mint,
      mdCodeBlock: pearl,
      mdCodeBlockBorder: edge,
      mdQuote: muted,
      mdQuoteBorder: violet,
      mdHr: edge,
      mdListBullet: violet,
      toolDiffAdded: mint,
      toolDiffRemoved: coral,
      toolDiffContext: muted,
      syntaxComment: muted,
      syntaxKeyword: violet,
      syntaxFunction: mint,
      syntaxVariable: pearl,
      syntaxString: '#b3dc99',
      syntaxNumber: amber,
      syntaxType: '#8cdbec',
      syntaxOperator: violet,
      syntaxPunctuation: muted,
      thinkingOff: edge,
      thinkingMinimal: dim,
      thinkingLow: '#62b6a0',
      thinkingMedium: mint,
      thinkingHigh: violet,
      thinkingXhigh: '#e0b3ff',
      thinkingMax: '#f1d4ff',
      bashMode: amber,
    },
    {
      selectedBg: '#294a43',
      searchMatchBg: '#38574b',
      userMessageBg: '#182f2c',
      customMessageBg: '#252337',
      toolPendingBg: '#19282e',
      toolSuccessBg: '#172b26',
      toolErrorBg: '#35232e',
    },
    mode,
    { name: 'biolume' },
  )
}
