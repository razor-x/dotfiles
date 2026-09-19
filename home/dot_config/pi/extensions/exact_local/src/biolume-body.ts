import type { Theme } from '@earendil-works/pi-coding-agent'

// UI experiment: one fixed silhouette; growth and compaction come later.
// Every cell shares its middle horizontal dots with its neighbours.
const silhouette = '⠒⠒⠛⡾⢷⣓⡾⠶⠒⠒⠲⡗⢾⣓⡻⠾⠒⠒⠚⡟⣲⢷⠺⠒⠒⠖⠲⠒'
const pulse = [
  'dim',
  'muted',
  'accent',
  'borderAccent',
  'thinkingHigh',
  'accent',
  'muted',
  'dim',
] as const
const radius = [0, 1, 2, 3, 3, 2, 1, 0]
const spores = ['·', '•', '●', '◉', '◎', '○', '·', '·']

export class LivingBody {
  private draft = ''
  private typedAt = -Infinity
  private working = false
  private startedAt = 0

  observe(draft: string, now: number): void {
    if (draft !== this.draft) {
      this.draft = draft
      this.typedAt = now
    }
  }

  setWorking(working: boolean, now: number): void {
    if (working && !this.working) {
      this.startedAt = now
    }
    this.working = working
  }

  isActive(now: number): boolean {
    return this.working || now - this.typedAt < 720
  }

  render(width: number, theme: Theme, now: number, still: boolean): string[] {
    const cells = [...silhouette.slice(0, Math.max(0, width - 1))]
    const step = still ? 2 : Math.floor((now - this.startedAt) / 240)
    const stage = step % pulse.length
    const end = cells.length - 1
    // Reflect at the tip rather than teleporting the light back to the root.
    const travel = end > 0 ? step % (2 * end) : 0
    const head = still ? 0 : end - Math.abs(end - travel)
    const listening = !still && now - this.typedAt < 720
    const line = cells
      .map((cell, index) => {
        const distance = Math.abs(index - head)
        let color: Parameters<Theme['fg']>[0] = 'borderMuted'
        if (this.working && distance <= (radius[stage] ?? 0)) {
          color = distance === 0 ? (pulse[stage] ?? 'accent') : 'accent'
        }
        if (index >= cells.length - 3 && (listening || this.draft.trim())) {
          color = listening
            ? (pulse[Math.floor((now - this.typedAt) / 90)] ?? 'accent')
            : 'accent'
        }
        // Bloom inside the strand, never beside it; restore each cell as the wave passes.
        if (this.working && index === head) {
          return theme.fg(pulse[stage] ?? 'accent', spores[stage] ?? '·')
        }
        return theme.fg(color, cell)
      })
      .join('')
    return [width > 0 ? ` ${line}` : '']
  }
}
