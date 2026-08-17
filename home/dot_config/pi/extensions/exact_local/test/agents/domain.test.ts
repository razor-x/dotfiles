import { describe, expect, it } from 'vitest'
import {
  createProvisioningRecord,
  InvalidAgentNameError,
  isManagedAgentRecordV1,
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

describe('isManagedAgentRecordV1', () => {
  const record = createProvisioningRecord({
    id,
    name: 'api-cache',
    repository: {
      commonDir: '/repos/example/.git',
      primaryWorktree: '/repos/example',
    },
    now,
  })

  it('accepts a valid provisioning record', () => {
    expect(isManagedAgentRecordV1(record)).toBe(true)
  })

  it.each([
    ['an unknown schema', { ...record, schemaVersion: 2 }],
    ['an unexpected field', { ...record, unexpected: true }],
    ['a malformed parent ID', { ...record, parentId: 'not-an-agent-id' }],
    [
      'a malformed resource',
      {
        ...record,
        resources: [{ kind: 'worktree', path: '/tmp/worktree' }],
      },
    ],
  ])('rejects %s', (_description, value) => {
    expect(isManagedAgentRecordV1(value)).toBe(false)
  })
})
