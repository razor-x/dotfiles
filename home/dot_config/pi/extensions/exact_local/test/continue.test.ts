import { describe, expect, it } from 'vitest'
import { continuePrompt } from '@/continue.ts'

describe('continuePrompt', () => {
  it('keeps the old prompt without input', () => {
    expect(continuePrompt('')).toBe('Continue.')
  })

  it('appends command input after the continue prompt', () => {
    expect(continuePrompt('with the next step')).toBe(
      'Continue.\n\nwith the next step',
    )
  })
})
