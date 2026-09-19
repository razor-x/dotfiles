import type { ToolResultEvent } from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it } from 'vitest'
import { looksLikeDenial } from '@/nono-sandbox.ts'

describe('looksLikeDenial', () => {
  it('recognizes failed permission errors', () => {
    expect(
      looksLikeDenial(
        fromPartial<ToolResultEvent>({
          isError: true,
          toolName: 'bash',
          content: [{ type: 'text', text: 'Permission denied' }],
        }),
      ),
    ).toBe(true)
  })

  it('ignores successful output', () => {
    expect(
      looksLikeDenial(
        fromPartial<ToolResultEvent>({
          isError: false,
          toolName: 'bash',
          content: [{ type: 'text', text: 'Permission denied' }],
        }),
      ),
    ).toBe(false)
  })
})
