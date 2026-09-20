import {
  type ExtensionAPI,
  FooterComponent,
  type Theme,
} from '@earendil-works/pi-coding-agent'
import { visibleWidth } from '@earendil-works/pi-tui'

// Chrome only: retain the native footer's accounting, statuses, and layout.
export default function shellChrome(pi: ExtensionAPI): void {
  let restore = () => {}
  pi.on('session_start', (_event, ctx) => {
    restore()
    if (ctx.mode !== 'tui') {
      return
    }
    // Pi exposes no decorator for the existing footer. Scope this reversible
    // render wrapper to the TUI session rather than duplicating its data model.
    const original = FooterComponent.prototype.render
    function render(this: FooterComponent, width: number): string[] {
      if (width < 12) {
        return original.call(this, width)
      }
      return [
        ...original
          .call(this, width - 4)
          .map((line) => shellRow(line, width, ctx.ui.theme)),
        ctx.ui.theme.fg('borderMuted', `╲${'━'.repeat(width - 2)}╱`),
      ]
    }
    FooterComponent.prototype.render = render
    restore = () => {
      if (FooterComponent.prototype.render === render) {
        FooterComponent.prototype.render = original
      }
    }
  })
  pi.on('session_shutdown', () => restore())
}

export function shellRow(line: string, width: number, theme: Theme): string {
  const padded = line + ' '.repeat(Math.max(0, width - 4 - visibleWidth(line)))
  const background = theme.getBgAnsi('customMessageBg')
  // Cursor and extension-status resets must not punch holes in the surface.
  const surface = theme.bg(
    'customMessageBg',
    ` ${padded} `
      .replaceAll('\x1b[0m', `\x1b[0m${background}`)
      .replaceAll('\x1b[49m', `\x1b[49m${background}`),
  )
  return theme.fg('border', '┃') + surface + theme.fg('borderMuted', '▏')
}
