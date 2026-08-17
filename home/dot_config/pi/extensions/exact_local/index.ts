import type {
  ExtensionAPI,
  ExtensionFactory,
} from '@earendil-works/pi-coding-agent'
import { default as agents } from './src/agents/index.ts'
import { default as cursorDownOrNewLine } from './src/cursor-down-or-newline.ts'

const extensions: ExtensionFactory[] = [cursorDownOrNewLine, agents]

export default async function exactLocal(pi: ExtensionAPI): Promise<void> {
  for (const extension of extensions) await extension(pi)
}
