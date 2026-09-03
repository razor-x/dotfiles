import type {
  ExtensionCommandContext,
  SessionEntry,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it, vi } from 'vitest'
import { deletePrompt } from '@/delete.ts'

const userPrompt = fromPartial<SessionEntry>({
  id: 'prompt',
  type: 'message',
  message: { role: 'user' },
})

function context(branch: SessionEntry[]): ExtensionCommandContext {
  return fromPartial<ExtensionCommandContext>({
    waitForIdle: vi.fn(() => Promise.resolve()),
    navigateTree: vi.fn(() => Promise.resolve({ cancelled: false })),
    sessionManager: { getBranch: () => branch },
    ui: { notify: vi.fn() },
  })
}

describe('deletePrompt', () => {
  it('navigates to the latest user prompt', async () => {
    const ctx = context([
      fromPartial<SessionEntry>({
        id: 'older-prompt',
        type: 'message',
        message: { role: 'user' },
      }),
      userPrompt,
      fromPartial<SessionEntry>({
        id: 'response',
        type: 'message',
        message: { role: 'assistant' },
      }),
    ])

    await deletePrompt(ctx)

    expect(ctx.navigateTree).toHaveBeenCalledWith('prompt')
  })

  it('warns when there is no prompt', async () => {
    const ctx = context([])

    await deletePrompt(ctx)

    expect(ctx.ui.notify).toHaveBeenCalledWith('No prompt to delete', 'warning')
  })
})
