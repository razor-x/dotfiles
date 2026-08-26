import type {
  ExtensionAPI,
  ExtensionFactory,
} from '@earendil-works/pi-coding-agent'
import { default as continueCommand } from './src/continue.ts'
import { default as kitty } from './src/kitty.ts'
import { default as localEditor } from './src/local-editor.ts'

const extensions: ExtensionFactory[] = [continueCommand, kitty, localEditor]

export default async function exactLocal(pi: ExtensionAPI): Promise<void> {
  for (const extension of extensions) {
    await extension(pi)
  }
}
