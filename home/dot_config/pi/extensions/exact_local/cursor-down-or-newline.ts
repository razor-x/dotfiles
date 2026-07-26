import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from '@earendil-works/pi-coding-agent'
import { matchesKey, type KeyId } from '@earendil-works/pi-tui'

const ACTION = 'local.editor.cursorDownOrNewLine'

export default function cursorDownOrNewLine(pi: ExtensionAPI): void {
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') return

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) => new LocalEditor(tui, theme, keybindings),
    )
  })
}

type EditorInternals = {
  isOnLastVisualLine: () => boolean
  moveCursor: (deltaLine: number, deltaCol: number) => void
}

class LocalEditor extends CustomEditor {
  private readonly cursorDownOrNewLineKeys: KeyId[]

  constructor(...args: ConstructorParameters<typeof CustomEditor>) {
    super(...args)
    this.cursorDownOrNewLineKeys = getKeys(args[2])
  }

  override handleInput(data: string): void {
    if (!this.cursorDownOrNewLineKeys.some((key) => matchesKey(data, key))) {
      super.handleInput(data)
      return
    }

    if (this.isShowingAutocomplete()) {
      super.handleInput(data)
      return
    }

    const editor = this as unknown as EditorInternals
    if (editor.isOnLastVisualLine()) {
      super.handleInput('\n')
      return
    }

    editor.moveCursor(1, 0)
    this.tui.requestRender()
  }
}

function getKeys(keybindings: KeybindingsManager): KeyId[] {
  const binding = keybindings.getUserBindings()[ACTION]
  if (typeof binding === 'string') return [binding]
  return binding ?? []
}
