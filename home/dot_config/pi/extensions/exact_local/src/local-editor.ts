import {
  CustomEditor,
  type ExtensionAPI,
} from '@earendil-works/pi-coding-agent'
import { Editor, matchesKey } from '@earendil-works/pi-tui'
import { copyPromptInputHandler } from './copy-prompt.ts'
import { cursorDownOrNewLineInputHandler } from './cursor-down-or-newline.ts'
import { thinkingInputHandler } from './cycle-thinking.ts'

export type EditorInputHandler = (editor: LocalEditor, data: string) => boolean

type EditorInternals = {
  autocompleteList?: { getSelectedItem: () => { label: string } | undefined }
  isOnLastVisualLine: () => boolean
  moveCursor: (deltaLine: number, deltaCol: number) => void
}

export default function localEditor(pi: ExtensionAPI): void {
  pi.on('session_start', (_event, ctx) => {
    if (ctx.mode !== 'tui') return

    ctx.ui.setEditorComponent(
      (tui, theme, keybindings) =>
        new LocalEditor(tui, theme, keybindings, [
          copyPromptInputHandler(keybindings, ctx.ui),
          thinkingInputHandler(keybindings, pi, ctx),
          cursorDownOrNewLineInputHandler(keybindings),
        ]),
    )
  })
}

export class LocalEditor extends CustomEditor {
  private readonly inputHandlers: EditorInputHandler[]
  private readonly localKeybindings: ConstructorParameters<
    typeof CustomEditor
  >[2]

  constructor(
    tui: ConstructorParameters<typeof CustomEditor>[0],
    theme: ConstructorParameters<typeof CustomEditor>[1],
    keybindings: ConstructorParameters<typeof CustomEditor>[2],
    inputHandlers: EditorInputHandler[] = [],
  ) {
    super(tui, theme, keybindings)
    this.localKeybindings = keybindings
    this.inputHandlers = inputHandlers
  }

  override handleInput(data: string): void {
    if (this.handleCursorRightAutocomplete(data)) return
    if (this.handleUpstreamTabInput(data)) return
    if (this.inputHandlers.some((handler) => handler(this, data))) return
    super.handleInput(data)
  }

  private handleCursorRightAutocomplete(data: string): boolean {
    if (
      !this.isAutocompleteVisible() ||
      !this.localKeybindings.matches(data, 'tui.editor.cursorRight')
    )
      return false

    const selected = (
      this as unknown as EditorInternals
    ).autocompleteList?.getSelectedItem()
    Editor.prototype.handleInput.call(this, '\t')
    if (selected?.label.endsWith('/'))
      Editor.prototype.handleInput.call(this, '\t')
    return true
  }

  // UPSTREAM: Pi sends Tab to Ctrl-I instead of the configured editor action.
  private handleUpstreamTabInput(data: string): boolean {
    const tabKeys = this.localKeybindings.getKeys?.('tui.input.tab') ?? ['tab']
    if (!tabKeys.some((key) => matchesKey(data, key))) return false

    const hasCustomTabBinding = () => {
      const bindings = Object.entries(this.localKeybindings.getUserBindings())
      type Binding = (typeof bindings)[number]

      const isLocalEditorAction = ([action]: Binding) =>
        action.startsWith('local.editor.')
      const includesTab = ([, binding]: Binding) =>
        (typeof binding === 'string' ? [binding] : (binding ?? [])).some(
          (key) => key.toLowerCase() === 'tab',
        )

      return bindings.some(
        (binding) => isLocalEditorAction(binding) && includesTab(binding),
      )
    }

    if (
      hasCustomTabBinding() &&
      this.inputHandlers.some((handler) => handler(this, data))
    )
      return true

    Editor.prototype.handleInput.call(this, data)
    return true
  }

  handleDefaultInput(data: string): void {
    super.handleInput(data)
  }

  isAutocompleteVisible(): boolean {
    return this.isShowingAutocomplete()
  }

  isOnLastVisualLineLocal(): boolean {
    return (this as unknown as EditorInternals).isOnLastVisualLine()
  }

  moveCursorBy(deltaLine: number, deltaCol: number): void {
    const editor = this as unknown as EditorInternals
    editor.moveCursor(deltaLine, deltaCol)
  }

  requestRender(): void {
    this.tui.requestRender()
  }
}
