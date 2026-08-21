import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
} from '@earendil-works/pi-coding-agent'
import { type KeyId, matchesKey } from '@earendil-works/pi-tui'
import { copyPrompt } from './copy-prompt.ts'
import { selectThinkingLevel } from './cycle-thinking.ts'

const cursorDownOrNewLineAction = 'local.editor.cursorDownOrNewLine'
const copyPromptAction = 'local.editor.copyPrompt'
const thinkingLowerAction = 'local.editor.thinkingLower'
const thinkingHigherAction = 'local.editor.thinkingHigher'

export default function cursorDownOrNewLine(pi: ExtensionAPI): void {
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') return

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new LocalEditor(
          tui,
          theme,
          keybindings,
          (offset) => selectThinkingLevel(pi, ctx, offset),
          (text) => void copyPrompt(text, ctx.ui),
        ),
    )
  })
}

type EditorInternals = {
  isOnLastVisualLine: () => boolean
  moveCursor: (deltaLine: number, deltaCol: number) => void
}

export class LocalEditor extends CustomEditor {
  private readonly cursorDownOrNewLineKeys: KeyId[]
  private readonly copyPromptKeys: KeyId[]
  private readonly thinkingLowerKeys: KeyId[]
  private readonly thinkingHigherKeys: KeyId[]
  private readonly selectThinkingLevel: (offset: -1 | 1) => void
  private readonly copyPrompt: (text: string) => void

  constructor(
    tui: ConstructorParameters<typeof CustomEditor>[0],
    theme: ConstructorParameters<typeof CustomEditor>[1],
    keybindings: ConstructorParameters<typeof CustomEditor>[2],
    selectThinkingLevel: (offset: -1 | 1) => void = () => undefined,
    copyPrompt: (text: string) => void = () => undefined,
  ) {
    super(tui, theme, keybindings)
    this.selectThinkingLevel = selectThinkingLevel
    this.copyPrompt = copyPrompt
    this.cursorDownOrNewLineKeys = getKeys(
      keybindings,
      cursorDownOrNewLineAction,
    )
    this.copyPromptKeys = getKeys(keybindings, copyPromptAction)
    this.thinkingLowerKeys = getKeys(keybindings, thinkingLowerAction)
    this.thinkingHigherKeys = getKeys(keybindings, thinkingHigherAction)
  }

  override handleInput(data: string): void {
    if (this.copyPromptKeys.some((key) => matchesKey(data, key))) {
      this.copyPrompt(this.getText())
      return
    }
    if (this.thinkingLowerKeys.some((key) => matchesKey(data, key))) {
      this.selectThinkingLevel(-1)
      return
    }
    if (this.thinkingHigherKeys.some((key) => matchesKey(data, key))) {
      this.selectThinkingLevel(1)
      return
    }
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

function getKeys(keybindings: KeybindingsManager, action: string): KeyId[] {
  const binding = keybindings.getUserBindings()[action]
  if (typeof binding === 'string') return [binding]
  return binding ?? []
}
