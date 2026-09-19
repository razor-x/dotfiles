import {
  type ExtensionAPI,
  type ExtensionContext,
  Theme,
} from '@earendil-works/pi-coding-agent'
import { LivingBody } from './biolume-body.ts'

export default function biolume(pi: ExtensionAPI): void {
  const body = new LivingBody()
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
    ctx.ui.setHiddenThinkingLabel()
    if (ctx.ui.theme.name === 'biolume' && previousTheme) {
      ctx.ui.setTheme(previousTheme)
    }
  }
  const apply = (ctx: ExtensionContext) => {
    if (ctx.mode !== 'tui') {
      return
    }
    applyTheme(ctx)
    ctx.ui.setWorkingVisible(false)
    ctx.ui.setHiddenThinkingLabel('')
    if (!enabled) {
      enabled = true
      ctx.ui.setWidget('biolume', (tui, liveTheme) => {
        requestRender = () => tui.requestRender()
        return {
          render(width) {
            const now = Date.now()
            // Drafts stay local; observing renders covers paste, undo, and history too.
            body.observe(ctx.ui.getEditorText(), now)
            if (!still && body.isActive(now)) {
              timer ??= setInterval(() => requestRender?.(), 90)
            } else {
              stop()
            }
            return body.render(width, liveTheme, now, still)
          },
          invalidate() {},
          dispose() {
            stop()
            requestRender = undefined
          },
        }
      })
    }
    if (still) {
      stop()
    }
    requestRender?.()
  }

  pi.on('session_start', (event, ctx) => {
    if (ctx.mode !== 'tui') {
      return
    }
    afterReload = event.reason === 'reload'
    apply(ctx)
  })
  pi.on('session_shutdown', (_event, ctx) => restore(ctx))
  pi.on('agent_start', (_event, ctx) => {
    body.setWorking(true, Date.now())
    requestRender?.()
    // Pi 0.85.1 reapplies saved colors after session_start on reload.
    if (ctx.mode === 'tui' && enabled && afterReload) {
      applyTheme(ctx)
      afterReload = false
    }
  })

  pi.on('agent_settled', () => {
    body.setWorking(false, Date.now())
    stop()
    requestRender?.()
  })

  pi.registerCommand('biolume', {
    description: 'Living body: on, still (no motion), off; resets on reload',
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
