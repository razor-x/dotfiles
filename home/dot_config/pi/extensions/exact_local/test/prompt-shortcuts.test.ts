import { describe, expect, it } from 'vitest'
import { promptShortcuts, shortcutPrompt } from '@/prompt-shortcuts.ts'

describe('prompt shortcuts', () => {
  it.each(Object.values(promptShortcuts))(
    'sends %s without input',
    (prompt) => {
      expect(shortcutPrompt(prompt, '')).toBe(prompt)
    },
  )

  it('appends command input after the shortcut prompt', () => {
    expect(shortcutPrompt(promptShortcuts['try-again'], 'with more care')).toBe(
      'Try again.\n\nwith more care',
    )
  })
})
