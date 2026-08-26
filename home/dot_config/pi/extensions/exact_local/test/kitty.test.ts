import type {
  ExtensionAPI,
  ExtensionContext,
  ExtensionHandler,
  SessionShutdownEvent,
  SessionStartEvent,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it, vi } from 'vitest'
import kitty from '@/kitty.ts'

describe('kitty', () => {
  it('marks TUI sessions and clears the marker at shutdown', () => {
    const write = vi
      .spyOn(process.stdout, 'write')
      .mockImplementation(() => true)
    const on = vi.fn()
    kitty(fromPartial<ExtensionAPI>({ on }))

    handler<SessionStartEvent>(on, 'session_start')(
      fromPartial<SessionStartEvent>({}),
      fromPartial<ExtensionContext>({ mode: 'tui' }),
    )
    handler<SessionShutdownEvent>(on, 'session_shutdown')(
      fromPartial<SessionShutdownEvent>({}),
      fromPartial<ExtensionContext>({ mode: 'tui' }),
    )

    expect(write).toHaveBeenNthCalledWith(
      1,
      '\x1b]1337;SetUserVar=IS_PI=MQ==\x07',
    )
    expect(write).toHaveBeenNthCalledWith(2, '\x1b]1337;SetUserVar=IS_PI\x07')
  })
})

function handler<Event>(
  on: ReturnType<typeof vi.fn>,
  event: string,
): ExtensionHandler<Event> {
  return fromPartial<ExtensionHandler<Event>>(
    on.mock.calls.find(([name]) => name === event)?.[1],
  )
}
