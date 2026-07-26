import type { ExtensionAPI, ExtensionFactory } from '@earendil-works/pi-coding-agent'
import { default as cursorDownOrNewLine } from './cursor-down-or-newline.ts'

const extensions: ExtensionFactory[] = [cursorDownOrNewLine]

export default async function exactLocal(pi: ExtensionAPI): Promise<void> {
  for (const extension of extensions) await extension(pi)
}
