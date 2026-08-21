import type { KeybindingsManager } from '@earendil-works/pi-coding-agent'
import { type KeyId, matchesKey } from '@earendil-works/pi-tui'

export function matchesBinding(
  data: string,
  keybindings: KeybindingsManager,
  action: string,
): boolean {
  const binding = keybindings.getUserBindings()[action]
  const keys: KeyId[] =
    typeof binding === 'string' ? [binding] : (binding ?? [])
  return keys.some((key) => matchesKey(data, key))
}
