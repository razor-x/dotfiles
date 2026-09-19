import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionHandler,
  SessionEntry,
  SessionShutdownEvent,
  SessionStartEvent,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { afterEach, describe, expect, it, vi } from 'vitest'
import reloadRuntime from '@/reload-runtime.ts'

const reloadResult = fromPartial<SessionEntry>({
  type: 'message',
  message: {
    role: 'toolResult',
    toolName: 'reload_runtime',
    toolCallId: 'reload-1',
    isError: false,
  },
})

afterEach(() => vi.useRealTimers())

describe('reload continuation', () => {
  it('resumes once from the fresh runtime after a successful reload tool result', async () => {
    vi.useFakeTimers()
    const app = setup([reloadResult])
    app.start('reload')
    expect(app.sendMessage).not.toHaveBeenCalled()
    await vi.runAllTimersAsync()
    expect(app.sendMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        customType: 'runtime-reloaded',
        content: expect.stringContaining('request-pi-ui'),
      }),
      { triggerTurn: true, deliverAs: 'followUp' },
    )
    app.start('reload')
    await vi.runAllTimersAsync()
    expect(app.sendMessage).toHaveBeenCalledOnce()
  })

  it.each(['startup', 'new', 'resume', 'fork'] as const)(
    'does not resume for %s',
    async (reason) => {
      vi.useFakeTimers()
      const app = setup([reloadResult])
      app.start(reason)
      await vi.runAllTimersAsync()
      expect(app.sendMessage).not.toHaveBeenCalled()
    },
  )

  it('does not continue after unrelated activity or failed reloads', async () => {
    vi.useFakeTimers()
    for (const branch of [
      [],
      [
        reloadResult,
        fromPartial<SessionEntry>({
          type: 'message',
          message: { role: 'user' },
        }),
      ],
      [
        fromPartial<SessionEntry>({
          type: 'message',
          message: {
            role: 'toolResult',
            toolName: 'reload_runtime',
            isError: true,
          },
        }),
      ],
    ]) {
      const app = setup(branch)
      app.start('reload')
      await vi.runAllTimersAsync()
      expect(app.sendMessage).not.toHaveBeenCalled()
    }
  })

  it('cancels the deferred continuation if that runtime shuts down', async () => {
    vi.useFakeTimers()
    const app = setup([reloadResult])
    app.start('reload')
    app.shutdown()
    await vi.runAllTimersAsync()
    expect(app.sendMessage).not.toHaveBeenCalled()
  })
})

function setup(entries: SessionEntry[]) {
  const branch = [...entries]
  const on = vi.fn()
  const sendMessage = vi.fn()
  reloadRuntime(
    fromPartial<ExtensionAPI>({
      on,
      registerCommand: vi.fn(),
      registerTool: vi.fn(),
      sendMessage,
      appendEntry: (customType: string, data: unknown) => {
        branch.push(
          fromPartial<SessionEntry>({ type: 'custom', customType, data }),
        )
      },
    }),
  )
  const ctx = fromPartial<ExtensionContext>({
    sessionManager: { getBranch: () => branch },
  })
  const start = fromPartial<ExtensionHandler<SessionStartEvent>>(
    on.mock.calls.find(([name]) => name === 'session_start')?.[1] ?? (() => {}),
  )
  const shutdown = fromPartial<ExtensionHandler<SessionShutdownEvent>>(
    on.mock.calls.find(([name]) => name === 'session_shutdown')?.[1] ??
      (() => {}),
  )
  return {
    sendMessage,
    start: (reason: SessionStartEvent['reason']) =>
      start({ type: 'session_start', reason }, ctx),
    shutdown: () =>
      shutdown({ type: 'session_shutdown', reason: 'reload' }, ctx),
  }
}
