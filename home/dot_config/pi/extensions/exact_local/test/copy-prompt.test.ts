import type { ExtensionUIContext } from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it, vi } from 'vitest'
import { copyPrompt } from '@/copy-prompt.ts'

describe('copyPrompt', () => {
  it('copies the prompt and notifies the user', async () => {
    const copy = vi.fn(() => Promise.resolve())
    const notify = vi.fn()

    await copyPrompt(
      'current prompt',
      fromPartial<ExtensionUIContext>({ notify }),
      copy,
    )

    expect(copy).toHaveBeenCalledWith('current prompt')
    expect(notify).toHaveBeenCalledWith('Copied prompt to clipboard', 'info')
  })
})
