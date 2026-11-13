import { fork } from 'node:child_process'
import { randomUUID } from 'node:crypto'
import { once } from 'node:events'
import { existsSync } from 'node:fs'
import { chmod, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { createServer } from 'node:net'
import { join } from 'node:path'
import { setTimeout as delay } from 'node:timers/promises'
import { fileURLToPath } from 'node:url'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  listTakeoverOwners,
  requestTakeover,
  startTakeoverService,
  type TakeoverService,
} from '@/lib/takeover.ts'

let directory: string
let sessionFile: string
let services: TakeoverService[]

beforeEach(async () => {
  directory = await mkdtemp('/tmp/pi-to-test-')
  sessionFile = join(directory, 'session.jsonl')
  await writeFile(sessionFile, 'history\n')
  services = []
})

afterEach(async () => {
  await Promise.all(services.map((service) => service.close()))
  await rm(directory, { recursive: true, force: true })
})

async function advertise(shutdown = vi.fn()) {
  const service = await startTakeoverService(directory)
  services.push(service)
  service.bind(() => ({ sessionFile, name: 'Test session' }), shutdown)
  const owner = (await listTakeoverOwners(directory)).find(
    (entry) => entry.socketPath === service.socketPath,
  )
  expect(owner).toBeDefined()
  if (!owner) {
    throw new Error('Missing test owner')
  }
  return { service, owner, shutdown }
}

describe('interactive takeover IPC', () => {
  it('discovers only reachable owners with an existing session file', async () => {
    await writeFile(join(directory, `${randomUUID()}.sock`), '')
    const { service, owner } = await advertise()
    expect(await listTakeoverOwners(directory)).toEqual([owner])
    service.bind(() => undefined, vi.fn())
    expect(await listTakeoverOwners(directory)).toEqual([])
    service.bind(
      () => ({
        sessionFile: join(directory, 'not-written.jsonl'),
        name: 'Blank',
      }),
      vi.fn(),
    )
    expect(await listTakeoverOwners(directory)).toEqual([])
  })

  it('rejects a public registry directory', async () => {
    await chmod(directory, 0o755)
    await expect(startTakeoverService(directory)).rejects.toThrow(
      'must be private',
    )
    await expect(listTakeoverOwners(directory)).rejects.toThrow(
      'must be private',
    )
  })

  it('rejects stale identity after a reload or session switch, even with the same PID', async () => {
    const { service, owner, shutdown } = await advertise()
    service.unbind()
    expect(await listTakeoverOwners(directory)).toEqual([])
    service.bind(() => ({ sessionFile, name: 'Reloaded' }), shutdown)
    const [reloaded] = await listTakeoverOwners(directory)
    expect(reloaded.pid).toBe(owner.pid)
    expect(reloaded.socketPath).toBe(owner.socketPath)
    expect(reloaded.token).not.toBe(owner.token)
    await expect(requestTakeover(owner)).rejects.toThrow('owner changed')
    expect(shutdown).not.toHaveBeenCalled()
  })

  it('rejects a spoofed token without requesting shutdown', async () => {
    const { owner, shutdown } = await advertise()
    await expect(
      requestTakeover({ ...owner, token: randomUUID() }),
    ).rejects.toThrow('owner changed')
    expect(shutdown).not.toHaveBeenCalled()
  })

  it('does not turn a failed shutdown into a successful handoff', async () => {
    const { owner } = await advertise(
      vi.fn(() => {
        throw new Error('shutdown failed')
      }),
    )
    await expect(requestTakeover(owner)).rejects.toThrow('refused')
    expect(await listTakeoverOwners(directory)).toHaveLength(1)
  })

  it('does not mistake an IPC disconnect for process exit while the endpoint is still alive', async () => {
    const socketPath = join(directory, `${randomUUID()}.sock`)
    const owner = {
      socketPath,
      sessionFile,
      name: 'Disconnected',
      token: randomUUID(),
      pid: process.pid,
    }
    const server = createServer((socket) => {
      socket.on('error', () => {})
      socket.write(`${JSON.stringify(owner)}\n`)
      socket.on('data', () => socket.end('accepted\n'))
    })
    await new Promise<void>((resolve) => server.listen(socketPath, resolve))
    try {
      await expect(requestTakeover(owner)).rejects.toThrow('still running')
    } finally {
      await new Promise<void>((resolve) => server.close(() => resolve()))
    }
  })

  it('times out without force-killing or releasing a still-running owner', async () => {
    const { owner, service, shutdown } = await advertise()
    await expect(requestTakeover(owner, 50)).rejects.toThrow('timed out')
    expect(shutdown).toHaveBeenCalledOnce()
    expect(existsSync(service.socketPath)).toBe(true)
    await expect(requestTakeover(owner)).rejects.toThrow(
      'already handling a takeover',
    )
    expect(shutdown).toHaveBeenCalledOnce()
  })

  it('accepts only one of two simultaneous takeover requests', async () => {
    const { owner, service, shutdown } = await advertise()
    const results = Promise.allSettled([
      requestTakeover(owner),
      requestTakeover(owner),
    ])
    await vi.waitFor(() => expect(shutdown).toHaveBeenCalledOnce())
    await service.close()
    const settled = await results
    expect(
      settled.filter((result) => result.status === 'fulfilled'),
    ).toHaveLength(1)
    expect(
      settled.filter((result) => result.status === 'rejected'),
    ).toHaveLength(1)
  })

  it('waits for real process exit, including cleanup after unbinding ownership', async () => {
    const child = fork(
      fileURLToPath(new URL('./fixtures/takeover-owner.ts', import.meta.url)),
      [directory, sessionFile],
      {
        execArgv: ['--experimental-strip-types'],
        stdio: ['ignore', 'pipe', 'pipe', 'ipc'],
      },
    )
    let stderr = ''
    child.stderr?.on('data', (data) => {
      stderr += String(data)
    })
    try {
      const ready = await Promise.race([
        once(child, 'message'),
        once(child, 'exit').then(() => {
          throw new Error(`Child exited before startup: ${stderr}`)
        }),
      ])
      expect(ready[0]).toBe('ready')
      const [owner] = await listTakeoverOwners(directory)
      expect(owner.pid).toBe(child.pid)
      const shutdown = once(child, 'message')
      let completed = false
      const handoff = requestTakeover(owner, 5000).then(() => {
        completed = true
      })
      expect((await shutdown)[0]).toBe('shutdown')
      await delay(30)
      expect(completed).toBe(false)
      expect(await readFile(sessionFile, 'utf8')).toBe('history\n')
      child.send('finish')
      await handoff
      expect(await readFile(sessionFile, 'utf8')).toBe(
        'history\nfinal cleanup\n',
      )
    } finally {
      child.kill()
      if (child.exitCode === null && child.signalCode === null) {
        await once(child, 'exit')
      }
    }
  })
})
