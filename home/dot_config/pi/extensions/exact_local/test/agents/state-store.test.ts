import { mkdtemp, readFile, readdir, rm, stat } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'
import { createProvisioningRecord } from '@/agents/domain.ts'
import {
  AgentAlreadyExistsError,
  FileAgentStore,
} from '@/agents/state-store.ts'

const id = '44444444-4444-4444-8444-444444444444'
const temporaryRoots: string[] = []

afterEach(async () => {
  await Promise.all(
    temporaryRoots.splice(0).map((path) => rm(path, { recursive: true })),
  )
})

describe('FileAgentStore', () => {
  it('atomically creates a restrictive record that a fresh store can reopen', async () => {
    const stateRoot = await temporaryStateRoot()
    const store = new FileAgentStore(stateRoot)
    const record = provisioningRecord()

    const stateFile = await store.create(record)

    expect(stateFile).toBe(join(stateRoot, 'agents', `${id}.json`))
    expect(JSON.parse(await readFile(stateFile, 'utf8'))).toEqual(record)
    expect((await stat(stateRoot)).mode & 0o777).toBe(0o700)
    expect((await stat(join(stateRoot, 'agents'))).mode & 0o777).toBe(0o700)
    expect((await stat(stateFile)).mode & 0o777).toBe(0o600)
    expect(await readdir(join(stateRoot, 'agents'))).toEqual([`${id}.json`])

    const reopened = new FileAgentStore(stateRoot)
    await expect(reopened.read(id)).resolves.toEqual(record)
  })

  it('does not replace an existing agent record', async () => {
    const stateRoot = await temporaryStateRoot()
    const store = new FileAgentStore(stateRoot)
    const original = provisioningRecord()
    await store.create(original)

    const replacement = { ...original, name: 'replacement' }
    await expect(store.create(replacement)).rejects.toBeInstanceOf(
      AgentAlreadyExistsError,
    )

    await expect(store.read(id)).resolves.toEqual(original)
    expect(await readdir(join(stateRoot, 'agents'))).toEqual([`${id}.json`])
  })
})

async function temporaryStateRoot(): Promise<string> {
  const path = await mkdtemp(join(tmpdir(), 'pi-agents-store-'))
  temporaryRoots.push(path)
  return path
}

function provisioningRecord() {
  return createProvisioningRecord({
    id,
    name: 'api-cache',
    repository: {
      commonDir: '/repos/example/.git',
      primaryWorktree: '/repos/example',
    },
    now: '2026-08-17T05:00:00.000Z',
  })
}
