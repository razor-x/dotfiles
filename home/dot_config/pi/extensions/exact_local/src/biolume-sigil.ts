import { createHash } from 'node:crypto'

function mirror(dots: number): number {
  return (
    ((dots & 0x07) << 3) |
    ((dots & 0x38) >> 3) |
    ((dots & 0x40) << 1) |
    ((dots & 0x80) >> 1)
  )
}

// A visual fingerprint, not a unique ID: up to 4,096 symmetric silhouettes.
export function sigil(text: string): string {
  const normalized = text.normalize('NFC').trim()
  if (!normalized) {
    return ' · '
  }
  const bytes = createHash('sha256').update(normalized).digest()
  const edge = bytes[0] || 0x04
  const middle = (bytes[1] ?? 0) & 0x47 || 0x02
  return [edge, middle | mirror(middle), mirror(edge)]
    .map((dots) => String.fromCodePoint(0x2800 + dots))
    .join('')
}

export class ListeningSigil {
  private text = ''
  private shape = ' · '
  private morphedAt = -Infinity
  private typedAt = -Infinity
  submitted = ' · '

  observe(text: string, now: number): void {
    if (text === this.text) {
      return
    }
    this.text = text
    this.typedAt = now
    // Keep a recognizable shape during a typing burst, changing at word boundaries.
    if (!text || /\s$/u.test(text) || now - this.morphedAt >= 300) {
      this.shape = sigil(text)
      this.morphedAt = now
    }
  }

  isListening(now: number): boolean {
    return this.text.trim().length > 0 && now - this.typedAt < 720
  }

  display(now: number, still: boolean): { glyph: string; label: string } {
    if (!this.text) {
      return { glyph: `  ${this.submitted}  `, label: '' }
    }
    if (still || now - this.typedAt >= 300) {
      this.shape = sigil(this.text)
    }
    const listening = !still && this.isListening(now)
    const frames = [' ·', ' ◦', '○ ', '◦ ', '· ', '  ', '  ', '  ']
    const left = listening
      ? (frames[Math.floor((now - this.typedAt) / 90)] ?? '  ')
      : '  '
    return {
      glyph: left + this.shape + [...left].reverse().join(''),
      label: listening ? 'listening' : '',
    }
  }
}
