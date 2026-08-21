import { getSupportedThinkingLevels } from '@earendil-works/pi-ai'
import type {
  ExtensionAPI,
  ExtensionContext,
} from '@earendil-works/pi-coding-agent'

export function selectThinkingLevel(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  offset: -1 | 1,
): void {
  if (ctx.model == null) return
  const levels = getSupportedThinkingLevels(ctx.model)
  const index = levels.indexOf(pi.getThinkingLevel())
  pi.setThinkingLevel(levels[(index + offset + levels.length) % levels.length])
}
