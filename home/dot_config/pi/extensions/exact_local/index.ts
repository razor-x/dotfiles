import type {
  ExtensionAPI,
  ExtensionFactory,
} from '@earendil-works/pi-coding-agent'
import { default as biolume } from './src/biolume.ts'
import { default as captureUi } from './src/capture-ui.ts'
import { default as deleteCommand } from './src/delete.ts'
import { default as kitty } from './src/kitty.ts'
import { default as localEditor } from './src/local-editor.ts'
import { default as nonoSandbox } from './src/nono-sandbox.ts'
import { default as promptShortcutCommands } from './src/prompt-shortcuts.ts'
import { default as reloadRuntime } from './src/reload-runtime.ts'

const extensions: ExtensionFactory[] = [
  promptShortcutCommands,
  captureUi,
  deleteCommand,
  kitty,
  localEditor,
  biolume,
  nonoSandbox,
  reloadRuntime,
]

export default async function exactLocal(pi: ExtensionAPI): Promise<void> {
  for (const extension of extensions) {
    await extension(pi)
  }
}
