import { stripVTControlCharacters } from 'node:util'
import type {
  SessionEntry,
  Theme,
  ThemeColor,
} from '@earendil-works/pi-coding-agent'
import { truncateToWidth } from '@earendil-works/pi-tui'

export type BloomNode = {
  id: string
  tool: string
  label: string
  kind: 'read' | 'change' | 'tool'
  state: 'running' | 'done' | 'failed' | 'interrupted'
}

// Keep display metadata only. The session transcript remains the source of truth.
export class Bloom {
  nodes: BloomNode[] = []
  phase = 'resting'
  active = false
  frame = 0

  start(id: string, tool: string, args: Record<string, unknown>): void {
    if (this.nodes.some((node) => node.id === id)) {
      return
    }
    const label = args.path ?? args.command ?? args.query ?? tool
    this.nodes.push({
      id,
      tool: clean(tool),
      label: clean(typeof label === 'string' ? label : tool).slice(0, 2000),
      kind: ['read', 'grep', 'find', 'ls'].includes(tool)
        ? 'read'
        : ['edit', 'write'].includes(tool)
          ? 'change'
          : 'tool',
      state: 'running',
    })
    // ponytail: show the latest 64 actions; use the transcript for older history.
    this.nodes = this.nodes.slice(-64)
  }

  finish(id: string, isError: boolean): void {
    const node = this.nodes.find((item) => item.id === id)
    if (node) {
      node.state = isError ? 'failed' : 'done'
    }
  }

  settle(): void {
    this.active = false
    this.phase = 'resting'
    for (const node of this.nodes) {
      if (node.state === 'running') {
        node.state = 'interrupted'
      }
    }
  }

  restore(entries: readonly SessionEntry[]): void {
    this.nodes = []
    for (const entry of entries) {
      if (entry.type !== 'message') {
        continue
      }
      const message = entry.message
      if (message.role === 'assistant') {
        for (const block of message.content) {
          if (block.type === 'toolCall') {
            this.start(block.id, block.name, block.arguments)
          }
        }
      } else if (message.role === 'toolResult') {
        this.finish(message.toolCallId, message.isError)
      }
    }
    this.settle()
  }
}

export function clean(text: string): string {
  return stripVTControlCharacters(text).replace(
    /[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]/gu,
    ' ',
  )
}

export function nodeColor(node: BloomNode): ThemeColor {
  if (node.state === 'failed') {
    return 'error'
  }
  if (node.state === 'interrupted') {
    return 'warning'
  }
  return node.kind === 'change' ? 'thinkingHigh' : 'accent'
}

export function nodeGlyph(node: BloomNode): string {
  if (node.state === 'failed') {
    return '×'
  }
  if (node.state === 'interrupted') {
    return '⊘'
  }
  if (node.state === 'running') {
    return '◌'
  }
  return node.kind === 'change' ? '◆' : node.kind === 'read' ? '○' : '◇'
}

export function renderBloom(
  bloom: Bloom,
  width: number,
  theme: Theme,
): string[] {
  if (width < 28) {
    return [
      truncateToWidth(theme.fg('accent', ` ◉ ${bloom.phase} · /bloom`), width),
    ]
  }
  const graphWidth = Math.min(92, width >= 80 ? Math.floor(width * 0.6) : width)
  const count = Math.max(1, Math.floor((graphWidth - 14) / 8))
  const nodes = bloom.nodes.slice(-count)
  const cells = Array.from({ length: 5 }, () =>
    Array.from({ length: graphWidth }, () => ({
      char: ' ',
      color: 'dim' as ThemeColor,
    })),
  )
  const put = (
    y: number,
    x: number,
    text: string,
    color: ThemeColor = 'borderMuted',
  ) => {
    for (const char of text) {
      const cell = cells[y]?.[x++]
      if (cell) {
        cell.char = char
        cell.color = color
      }
    }
  }
  const ring: ThemeColor = bloom.active ? 'accent' : 'dim'
  put(0, 3, '⢀⣀⣀', ring)
  put(1, 1, '⢠⠊   ⠑⡄', ring)
  put(2, 0, '·⡇     ⢸', ring)
  put(3, 1, '⠑⢄   ⡠⠊', ring)
  put(4, 3, '⠉⠉⠁', ring)
  const nucleus = bloom.active
    ? ['·', '○', '◎', '◉', '◎', '○'][bloom.frame % 6]
    : '◉'
  put(2, 4, nucleus ?? '◉', bloom.phase === 'waiting' ? 'warning' : ring)
  const end = 12 + nodes.length * 8
  put(2, 8, '─'.repeat(Math.max(3, end - 8)))
  if (bloom.active) {
    put(2, 8 + (bloom.frame % Math.max(1, end - 8)), '·', 'accent')
  }
  nodes.forEach((node, i) => {
    const x = 14 + i * 8
    const y = node.kind === 'read' ? 0 : node.kind === 'change' ? 4 : 2
    const color = nodeColor(node)
    if (y !== 2) {
      put(2, x - 3, y === 0 ? '┴' : '┬')
      put(y === 0 ? 1 : 3, x - 3, '│')
      put(y, x - 3, y === 0 ? '╭──' : '╰──')
    }
    put(y, x, nodeGlyph(node), color)
    put(
      y,
      x + 1,
      String(bloom.nodes.indexOf(node) + 1).padStart(2, '0'),
      'muted',
    )
    if (node.state === 'running' && bloom.active && bloom.frame % 2 === 0) {
      put(y, x, '●', color)
    }
  })
  const latest = bloom.nodes.at(-1)
  const running = bloom.nodes.filter((node) => node.state === 'running').length
  const failed = bloom.nodes.filter((node) => node.state === 'failed').length
  const notes = [
    theme.fg('muted', 'B I O L U M E'),
    theme.fg(
      'accent',
      running
        ? `${running} tool${running === 1 ? '' : 's'} active`
        : bloom.phase,
    ),
    latest
      ? theme.fg(
          nodeColor(latest),
          `${nodeGlyph(latest)} ${latest.tool} · ${latest.state}`,
        )
      : '',
    theme.fg('muted', latest?.label ?? 'A trace grows here as Pi works.'),
    theme.fg(
      failed ? 'error' : 'dim',
      `${failed ? `${failed} failed · ` : ''}/bloom inspect · /session stats`,
    ),
  ]
  const lines = cells.map((row, y) => {
    const graph = row.map(({ char, color }) => theme.fg(color, char)).join('')
    return truncateToWidth(graph + (width >= 80 ? `  ${notes[y]}` : ''), width)
  })
  if (width < 80) {
    lines.push(truncateToWidth(`${notes[1]} · ${notes[4]}`, width))
  }
  return lines
}
