import { describe, expect, it, vi } from 'vitest'
import { AgentsApplication } from '@/agents/application.ts'
import type { ManagedAgentRecordV1 } from '@/agents/domain.ts'
import type { AgentStore } from '@/agents/state-store.ts'

const id = '22222222-2222-4222-8222-222222222222'
const now = new Date('2026-08-17T05:00:00.000Z')

describe('AgentsApplication.beginPromotion', () => {
  it('persists provisioning intent without accepting resource-effect adapters', async () => {
    const create = vi.fn(
      async (_record: ManagedAgentRecordV1) =>
        `/state/pi-agents/agents/${id}.json`,
    )
    const agents: AgentStore = {
      create,
      read: async () => {
        throw new Error('unexpected read')
      },
    }
    const resolvePrimary = vi.fn(async () => ({
      commonDir: '/repos/example/.git',
      primaryWorktree: '/repos/example',
    }))
    const application = new AgentsApplication({
      agents,
      repositories: { resolvePrimary },
      clock: { now: () => now },
      ids: { generate: () => id },
    })

    const result = await application.beginPromotion({
      cwd: '/repos/example',
      name: 'api-cache',
    })

    expect(resolvePrimary).toHaveBeenCalledOnce()
    expect(resolvePrimary).toHaveBeenCalledWith('/repos/example', undefined)
    expect(create).toHaveBeenCalledOnce()
    expect(create).toHaveBeenCalledWith({
      schemaVersion: 1,
      id,
      revision: 0,
      name: 'api-cache',
      parentId: null,
      repository: {
        commonDir: '/repos/example/.git',
        primaryWorktree: '/repos/example',
      },
      resources: [],
      lifecycle: 'provisioning',
      createdAt: now.toISOString(),
      updatedAt: now.toISOString(),
    })
    expect(result).toEqual({
      id,
      stateFile: `/state/pi-agents/agents/${id}.json`,
      lifecycle: 'provisioning',
    })
  })
})
