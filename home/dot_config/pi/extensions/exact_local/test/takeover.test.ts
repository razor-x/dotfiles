import { fileURLToPath } from 'node:url'
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionHandler,
  SessionShutdownEvent,
  SessionStartEvent,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  listTakeoverOwners,
  requestTakeover,
  startTakeoverService,
  type TakeoverOwner,
  type TakeoverService,
} from '@/lib/takeover.ts'
import takeover from '@/takeover.ts'

vi.mock('@/lib/takeover.ts', () => ({
  listTakeoverOwners: vi.fn(),
  requestTakeover: vi.fn(),
  startTakeoverService: vi.fn(),
}))

const owner: TakeoverOwner = {
  pid: process.pid + 1,
  socketPath: '/tmp/owner.sock',
  token: 'test-token',
  sessionFile: '/sessions/target.jsonl',
  name: 'Target',
}

beforeEach(() => {
  vi.resetAllMocks()
  Reflect.deleteProperty(globalThis, Symbol.for('dotfiles.pi.takeover'))
  vi.mocked(listTakeoverOwners).mockResolvedValue([owner])
  vi.mocked(requestTakeover).mockResolvedValue()
})

function setup(mode: ExtensionCommandContext['mode'] = 'tui') {
  const on = vi.fn()
  const registerCommand = vi.fn()
  takeover(fromPartial<ExtensionAPI>({ on, registerCommand }))
  const ctx = fromPartial<ExtensionCommandContext>({
    mode,
    waitForIdle: vi.fn(() => Promise.resolve()),
    switchSession: vi.fn(() => Promise.resolve({ cancelled: false })),
    sessionManager: {
      getSessionFile: () => fileURLToPath(import.meta.url),
      getSessionName: () => 'Current session',
    },
    ui: {
      notify: vi.fn(),
      select: vi
        .fn()
        .mockImplementationOnce((_title: string, labels: string[]) =>
          Promise.resolve(labels[0]),
        )
        .mockImplementationOnce((_title: string, labels: string[]) =>
          Promise.resolve(labels[0]),
        ),
    },
    shutdown: vi.fn(),
  })
  const handler = fromPartial<
    (args: string, ctx: ExtensionCommandContext) => Promise<void>
  >(
    registerCommand.mock.calls.find(([name]) => name === 'takeover')?.[1]
      .handler,
  )
  const start = fromPartial<ExtensionHandler<SessionStartEvent>>(
    on.mock.calls.find(([name]) => name === 'session_start')?.[1],
  )
  const shutdown = fromPartial<ExtensionHandler<SessionShutdownEvent>>(
    on.mock.calls.find(([name]) => name === 'session_shutdown')?.[1],
  )
  return {
    ctx,
    run: () => handler('', ctx),
    start: (reason: SessionStartEvent['reason'] = 'startup') =>
      start({ type: 'session_start', reason }, ctx),
    shutdown: () =>
      shutdown({ type: 'session_shutdown', reason: 'reload' }, ctx),
  }
}

describe('/takeover', () => {
  it('defaults confirmation to yes and waits for handoff before switching', async () => {
    const app = setup()
    const handoff = Promise.withResolvers<void>()
    vi.mocked(requestTakeover).mockReturnValue(handoff.promise)
    const run = app.run()
    await vi.waitFor(() => expect(requestTakeover).toHaveBeenCalledWith(owner))
    expect(app.ctx.switchSession).not.toHaveBeenCalled()
    expect(app.ctx.ui.select).toHaveBeenLastCalledWith(
      expect.stringContaining(`PID ${owner.pid}`),
      ['Yes, take over', 'No'],
    )
    handoff.resolve()
    await run
    expect(app.ctx.switchSession).toHaveBeenCalledWith(owner.sessionFile)
  })

  it.each(['No', undefined])(
    'does nothing when confirmation is %s',
    async (answer) => {
      const app = setup()
      vi.mocked(app.ctx.ui.select)
        .mockReset()
        .mockImplementationOnce((_title: string, labels: string[]) =>
          Promise.resolve(labels[0]),
        )
        .mockResolvedValueOnce(answer)
      await app.run()
      expect(requestTakeover).not.toHaveBeenCalled()
      expect(app.ctx.switchSession).not.toHaveBeenCalled()
    },
  )

  it('does nothing when the session picker is cancelled', async () => {
    const app = setup()
    vi.mocked(app.ctx.ui.select).mockReset().mockResolvedValue(undefined)
    await app.run()
    expect(requestTakeover).not.toHaveBeenCalled()
    expect(app.ctx.switchSession).not.toHaveBeenCalled()
  })

  it.each(['rpc', 'print', 'json'] as const)(
    'does not register an owner or run in %s mode',
    async (mode) => {
      const app = setup(mode)
      await app.start()
      await app.run()
      expect(startTakeoverService).not.toHaveBeenCalled()
      expect(listTakeoverOwners).not.toHaveBeenCalled()
    },
  )

  it('excludes this process and explains when no owner is available', async () => {
    const app = setup()
    vi.mocked(listTakeoverOwners).mockResolvedValue([
      { ...owner, pid: process.pid },
    ])
    await app.run()
    expect(app.ctx.ui.select).not.toHaveBeenCalled()
    expect(app.ctx.ui.notify).toHaveBeenCalledWith(
      expect.stringContaining('extension loaded'),
      'info',
    )
  })

  it('refuses a session already advertised by multiple writers', async () => {
    const app = setup()
    vi.mocked(listTakeoverOwners)
      .mockResolvedValueOnce([owner])
      .mockResolvedValueOnce([owner, { ...owner, pid: owner.pid + 1 }])
    await app.run()
    expect(requestTakeover).not.toHaveBeenCalled()
    expect(app.ctx.switchSession).not.toHaveBeenCalled()
    expect(app.ctx.ui.notify).toHaveBeenCalledWith(
      expect.stringContaining('multiple owners'),
      'error',
    )
  })

  it('leaves the current session alone on handoff failure or timeout', async () => {
    const app = setup()
    vi.mocked(requestTakeover).mockRejectedValue(
      new Error('shutdown timed out'),
    )
    await app.run()
    expect(app.ctx.switchSession).not.toHaveBeenCalled()
    expect(app.ctx.ui.notify).toHaveBeenCalledWith(
      expect.stringContaining('shutdown timed out'),
      'error',
    )
  })

  it('does not retry a switch cancelled by another extension', async () => {
    const app = setup()
    vi.mocked(app.ctx.switchSession).mockResolvedValue({ cancelled: true })
    await app.run()
    expect(requestTakeover).toHaveBeenCalledOnce()
    expect(app.ctx.switchSession).toHaveBeenCalledOnce()
  })
})

describe('owner registration lifecycle', () => {
  it('rebinds the process-scoped service on reload without closing its connections', async () => {
    const app = setup()
    const service = fromPartial<TakeoverService>({
      bind: vi.fn(),
      unbind: vi.fn(),
      close: vi.fn(),
    })
    vi.mocked(startTakeoverService).mockResolvedValue(service)
    await app.start()
    await app.shutdown()
    await app.start('reload')
    expect(startTakeoverService).toHaveBeenCalledOnce()
    expect(service.bind).toHaveBeenCalledTimes(2)
    expect(service.unbind).toHaveBeenCalledOnce()
    expect(service.close).not.toHaveBeenCalled()
    const [describeSession, shutdown] = vi.mocked(service.bind).mock.calls[1]
    expect(describeSession()).toEqual({
      sessionFile: fileURLToPath(import.meta.url),
      name: 'Current session',
    })
    shutdown()
    expect(app.ctx.shutdown).toHaveBeenCalledOnce()
  })

  it('does not advertise ephemeral or not-yet-written sessions', async () => {
    const app = setup()
    const service = fromPartial<TakeoverService>({ bind: vi.fn() })
    vi.mocked(startTakeoverService).mockResolvedValue(service)
    await app.start()
    const [describeSession] = vi.mocked(service.bind).mock.calls[0]
    app.ctx.sessionManager.getSessionFile = () => undefined
    expect(describeSession()).toBeUndefined()
    app.ctx.sessionManager.getSessionFile = () => '/not-written/session.jsonl'
    expect(describeSession()).toBeUndefined()
  })

  it('reports registration failures and retries initialization on the next start', async () => {
    const app = setup()
    const service = fromPartial<TakeoverService>({ bind: vi.fn() })
    vi.mocked(startTakeoverService)
      .mockRejectedValueOnce(new Error('IPC unavailable'))
      .mockResolvedValueOnce(service)
    await app.start()
    expect(app.ctx.ui.notify).toHaveBeenCalledWith(
      expect.stringContaining('IPC unavailable'),
      'warning',
    )
    await app.start('reload')
    expect(service.bind).toHaveBeenCalledOnce()
  })
})
