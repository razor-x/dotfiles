import { describe, expect, it } from 'vitest'
import { defaultAgentsStateRoot } from '@/agents/config.ts'

describe('defaultAgentsStateRoot', () => {
  it('uses the Pi-specific state directory', () => {
    expect(
      defaultAgentsStateRoot({ XDG_STATE_HOME: '/state' }, '/home/example'),
    ).toBe('/state/pi-agents')
  })

  it('uses the XDG default when no state home is configured', () => {
    expect(defaultAgentsStateRoot({}, '/home/example')).toBe(
      '/home/example/.local/state/pi-agents',
    )
  })
})
