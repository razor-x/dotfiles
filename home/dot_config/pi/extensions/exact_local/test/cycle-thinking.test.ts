import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent'
import { fromPartial } from '@total-typescript/shoehorn'
import { describe, expect, it, vi } from 'vitest'
import { selectThinkingLevel } from '@/cycle-thinking.ts'

describe('selectThinkingLevel', () => {
  it.each([
    [-1, 'low'],
    [1, 'high'],
  ] as const)('moves %i from medium', (offset, expected) => {
    const setThinkingLevel = vi.fn()
    const pi = fromPartial<ExtensionAPI>({
      getThinkingLevel: () => 'medium',
      setThinkingLevel,
    })
    const ctx = fromPartial<ExtensionContext>({
      model: { reasoning: true },
    })

    selectThinkingLevel(pi, ctx, offset)

    expect(setThinkingLevel).toHaveBeenCalledWith(expected)
  })
})
