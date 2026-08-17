import { describe, expect, it } from 'vitest'
import {
  createProvisioningRecord,
  InvalidAgentNameError,
} from '@/agents/domain.ts'

const id = '11111111-1111-4111-8111-111111111111'
const now = '2026-08-17T05:00:00.000Z'

describe('createProvisioningRecord', () => {
  it('creates revision-zero durable intent with no resources', () => {
    const repository = {
      commonDir: '/repos/example/.git',
      primaryWorktree: '/repos/example',
    }

    const record = createProvisioningRecord({
      id,
      name: '  api cache  ',
      repository,
      now,
    })

    expect(record).toEqual({
      schemaVersion: 1,
      id,
      revision: 0,
      name: 'api cache',
      parentId: null,
      repository,
      resources: [],
      lifecycle: 'provisioning',
      createdAt: now,
      updatedAt: now,
    })
    expect(record.repository).not.toBe(repository)
  })

  it('rejects an empty display name', () => {
    expect(() =>
      createProvisioningRecord({
        id,
        name: '   ',
        repository: {
          commonDir: '/repos/example/.git',
          primaryWorktree: '/repos/example',
        },
        now,
      }),
    ).toThrow(InvalidAgentNameError)
  })
})
