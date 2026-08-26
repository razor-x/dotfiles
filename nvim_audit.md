## Keymap audit scope

Compared mappings explicitly configured in the old and new source. Plugin-default mappings are summarized rather than exhaustively listed.

## Strong overlap

These workflows and mostly the same keys survived:

| Area | Preserved mappings |
|---|---|
| Editing model | Insert `<CR>` exits, `<BS>` moves left; normal/visual `<CR>` opens command line |
| Motions | `q → ge`, `Q → gE`, `U → redo`, `<C-R> → U`, `& → :&&` |
| Macros | `<Tab>`, `<Tab><Tab>`, `<C-Q>` |
| Command line | `<BS>`, `<C-H>`, `<C-L>`, `<C-A>`, `<C-J>`, `<C-K>`, `<S-Esc>` |
| Files | `<Leader>n`, `<Leader>E`, `<Leader>s`, `<Leader>S` |
| Windows | `<Leader>{hjkl}`, `<Leader>{HJKL}`, `<Leader><CR>`, `<Leader>q/Q` |
| Tabs | `<Leader><Tab>`, `<Leader><S-Tab>`, `<C-,>`, `<C-.>` |
| Search/history | `<Leader>o`, `<Leader>:`, `<Leader>/`, `<Leader>?` |
| Clipboard substitution | `<Leader>p/P`, `<C-;>`, `<C-;><C-;>`, `yoP` |
| Comments | `\\` |
| Cut/delete | `m`, `mm`, `M` |
| Yank ring | `p/P`, `<C-N>/<C-P>` |
| Substitution | `:`, `::` |
| Buffer removal | `<Leader>w/W` |
| Undo tree | `<Leader>u/U` |
| Line movement | `<C-->`, `<C-=>` |
| Split movement | `<C-h/j/k/l>` |
| Split resizing | `<A-h/j/k/l>` |
| Main pickers | `<Leader>a` grep, `<Leader>b` buffers, `<Leader>e` Git files |
| File explorer | `<Leader>i/I`, though `I` now closes rather than toggles |
| Core FZF replacements | `<Leader>ff` files and `<Leader>fg` Git files |
| Git | `<Leader>ga/gc/gs/gl/gd` retain broadly similar workflows |
| Color column | `yom` |

## Same functionality, changed keys

| Old | New | Function |
|---|---|---|
| `<Leader>c/C/cc` | `<Leader>y/Y/yy` | System clipboard yank |
| `<Leader>y` | `<Leader>cy` | Yank history |
| `<Leader>+` | `<Leader>f` | Format |
| `<Leader>d` | `<Leader>D`, `<Leader>dD` | Buffer/workspace diagnostics |
| `[g` / `]g` | `[d` / `]d` | Previous/next diagnostic |
| `<Leader>fa` | `<Leader>a` or `<Leader>cg` | Project grep |
| `<Leader>fj` | `<Leader>b` or `<Leader>fb` | Buffers |
| `<Leader>fd` | `<Leader>ch` | Help |
| `<Leader>fq` | `<Leader>cm` | Marks |
| `<Leader>fl/fk` | `<Leader>cb` | Buffer lines |
| `<Leader>f<Space>` | `<Leader>f:` | Command history |
| `<Leader>f/` | `<Leader>c/` | Search history |
| `<Leader>fv` | `<Leader>cC` | Commands |
| `<Leader>fm` | `<Leader>ck` | Keymaps |
| `<Leader>gb` | `<Leader>gb` | Changed from blame to branches |
| `gR` | Native `grn` | LSP rename |

The `<Leader>gb` reuse is the clearest semantic collision: the same key now means Git branches rather than blame.

## New keymap surface

### Picker hierarchy

The new config adds large, organized namespaces:

- `<Leader>f…`: files, projects, recent files, history, notifications
- `<Leader>c…`: grep, diagnostics, commands, help, marks, jumps, keymaps, lists
- `<Leader>g…`: Git branches, log, status, stash, diffs, GitHub issues and PRs
- `gd`, `gD`, `gr`, `gI`, `gy`, `gai`, `gao`: LSP navigation
- `<C-g>…`: picker controls and insert-file-path behavior

### Editing

- `s/S/r/R`: Flash navigation
- `gS`: TreeSJ split/join
- `X/XX`: exchange operator
- `gp/gP`: Yanky indented paste
- `<Leader>cy`: yank-history picker
- `<C-Space>`: snippet picker
- `<C-F>`: path completion
- `[b/d/j/l/q/n/x` families: `mini.bracketed`
- `[|` / `]|`: first/last comment
- `<`, `>`, `+`, `_`: move selections
- `sa/sd/sr/…`: `mini.surround` defaults

### Management and UI

- `<F5>`: restart Neovim
- `<F7>/<F8>`: expose `[`/`]` prefixes
- `<Leader>N`: reset session
- `<A-H/J/K/L>`: swap split buffers
- `<Leader>?`: WhichKey
- `<Leader>d…`, `<C-Space>`: Pi integration
- Global `yo…` and local `\o…` toggle families

## Old mappings that could be ported immediately

These do not require restoring an old plugin:

1. **Previous split**
   ```text
   <C-\> → SmartSplits.move_cursor_previous
   ```
   Present in the old Smart Splits setup, missing from the new one.

2. **LSP rename compatibility**
   ```text
   gR → vim.lsp.buf.rename()
   ```
   Useful only if you prefer the old key over native `grn`.

3. **Old format alias**
   ```text
   <Leader>+ → Conform format
   ```
   Could coexist with `<Leader>f`.

4. **Old project-grep alias**
   ```text
   <Leader>A → Snacks picker grep
   ```
   Harmless if the old muscle memory remains useful.

5. **Quickfix/location-list toggles**
   ```text
   <Leader>xx → quickfix toggle
   <Leader>xl → location-list toggle
   ```
   Implement using native list commands; already tracked in `dotfiles/TODO`.

6. **Reverse jump-list key**
   ```text
   <C-Tab> → <Tab>/<C-I>
   ```
   The old config provided this; the new one does not.

7. **Visual `*`/`#` search**
   Can be implemented directly without restoring `vim-visual-star-search`.

## Do not port unchanged

- `<Leader><Leader> → za`: now conflicts with the new shifted-key alias namespace.
- `<C-CR>` split-line mapping: reserved in the TODO for a future action menu.
- `<Leader>y` yank history: now used for clipboard yank.
- `<Leader>d` Trouble: conflicts with the new Pi/diagnostic namespace.
- `<Leader>gb` blame: now Git branches.
- `<Leader>m/M/mm` clipboard deletion: intentionally omitted and `m/M` are being reconsidered.
- Old terminal, test, Tagbar, Unicode, rainbow, Lexima and documentation mappings: restore only with their corresponding functionality.

One discrepancy: `doc/dotfiles.txt` documents `<C-CR>` as split-line, but the current source only maps `<S-CR>`.

## 1. Mini covers the core well

Your selected Mini modules cover the expected editor foundation:

- Editing: `mini.ai`, `comment`, `move`, `pairs`, `surround`, `trailspace`
- Navigation: `mini.bracketed`, `indentscope`
- Buffers/UI primitives: `mini.bufremove`, `icons`, `cmdline`
- Completion: `mini.completion`, `snippets`, `keymap`
- Defaults/utilities: `mini.basics`, `extra`

I would not add another Mini module by default. The current baseline is coherent.

Notably:

- `mini.test` tests Neovim plugins; it is **not** a project test runner.
- `mini.git` and `mini.diff` are intentionally narrower than your current Git stack.
- `mini.hipatterns` could handle some color highlighting, but choosing a dedicated colorizer is reasonable.

## 2. Alternatives you selected over Mini

| Mini module | Selected alternative | Assessment |
|---|---|---|
| `mini.deps` | Lazy.nvim | Keep Lazy |
| `mini.pick` | Snacks picker | Keep Snacks |
| `mini.files` | Oil + Snacks explorer | Both are good, but confirm each has a distinct role |
| `mini.sessions` | `auto-session` | Keep, but verify restore semantics |
| `mini.git` | Neogit | Keep Neogit |
| `mini.diff` | Gitsigns + CodeDiff | Keep Gitsigns; validate CodeDiff’s distinct role |
| `mini.jump2d` | Flash | Keep Flash |
| `mini.jump` | Native `f/F/t/T` | Correct |
| `mini.splitjoin` | TreeSJ | Keep TreeSJ |
| `mini.operators` | Substitute + native operators | Reasonable |
| `mini.clue` | WhichKey | Keep WhichKey |
| `mini.statusline` | Lualine | Keep Lualine |
| `mini.tabline` | Native tabline | Correct |
| `mini.hipatterns` | `nvim-colorizer.lua` | Keep colorizer |
| `mini.base16/colors/hues` | Catppuccin | Correct |
| `mini.notify` | Native `vim.notify` | Correct |
| `mini.starter` | Nothing | Correct if start screens are unwanted |
| `mini.visits` | Snacks recent/projects | Good enough |
| `mini.fuzzy` | Snacks matcher | Correct |

One TODO inconsistency: `mini.sessions` is marked rejected in favor of `auto-session`, but the proposed-keybind table still says:

```text
mini.sessions │ Use <leader>xs to select/read
```

That row should refer to `auto-session` or be removed.

## 3. Features legitimately outside Mini’s scope

These justify external plugins or native implementations:

### Development infrastructure

- LSP server configuration: `nvim-lspconfig`
- Formatting: Conform
- Non-LSP linting: currently not covered
- Tree-sitter parser management
- Test execution
- Debugging/task execution, if wanted

### Rich interfaces

- Git porcelain: Neogit
- Git signs/blame: Gitsigns
- GitHub review/editing: Octo
- Diagnostics list: Trouble
- Persistent symbol sidebar: potentially Aerial
- Editable quickfix: potentially Quicker
- Rich fold presentation: potentially UFO

### Specialized editing

- Rainbow delimiters
- Mark visualization
- Unicode lookup
- VimTeX
- Clojure REPL/paredit
- Haskell tooling
- Emmet/tag closing
- Thesaurus lookup
- Abolish coercions
- Project alternate-file rules

These should not be forced into Mini-shaped replacements.

## 4. Plugins not currently on your radar

### Strong matches for existing TODO items

| Plugin | Relevant TODO need | Recommendation |
|---|---|---|
| `mfussenegger/nvim-lint` | Replacing ALE’s non-LSP linting | Consider when an executable is a linter but not an LSP server; Conform does not lint |
| `MagicDuck/grug-far.nvim` | Project-wide find/replace | Consider after trying Snacks grep → quickfix → native `:cfdo` |
| `windwp/nvim-ts-autotag` | Closing and renaming HTML/XML tags | Best focused replacement for `vim-closetag` |
| `mrcjkb/haskell-tools.nvim` | Restoring Haskell tooling | Consider only if plain HLS through `nvim-lspconfig` is insufficient |
| `Olical/conjure` | Clojure REPL | Modern alternative to Fireplace/Salve |
| `julienvincent/nvim-paredit` | Clojure structural editing | Modern Tree-sitter alternative to Vim sexp plugins |
| `nvim-neotest/neotest` | Structured test execution | Consider if you want test discovery/results UI |
| `stevearc/overseer.nvim` | General project tasks | Consider only if the need is broader than tests |

For simple cross-language test commands, restoring `vim-test` is smaller than assembling Neotest plus adapters.

### Already on your radar and appropriately scoped

- `rainbow-delimiters.nvim`: direct fit; likely add.
- `marks.nvim`: add only if sign-column marks matter.
- Aerial: add only if a persistent symbol outline matters.
- `nvim-ufo`: wait until native Tree-sitter folding demonstrably fails.
- Quicker: good if editable quickfix is the actual requirement.
- `vim-abolish`: still the straightforward choice for coercions.

## Existing plugin overlap to resolve

Your largest scope risk is not missing plugins; it is overlapping interfaces:

1. **Oil + Snacks explorer**
   - Sensible split: Oil for editing directories, Snacks for sidebar exploration.
   - Remove one if that distinction is not real in practice.

2. **Undotree + Snacks undo picker**
   - Undotree gives history structure/diff.
   - Snacks gives fast lookup.
   - Keep both only if both workflows get used.

3. **Trouble + Snacks diagnostic pickers**
   - Trouble is persistent and navigable.
   - Snacks is transient search.
   - Avoid duplicate mappings for the same entry point.

4. **Neogit + Gitsigns + CodeDiff + Snacks Git**
   - Neogit: operations.
   - Gitsigns: buffer hunks/blame.
   - CodeDiff: dedicated diff view.
   - Snacks: searching Git data.
   - This stack is justified only if CodeDiff provides something Neogit’s diff flow does not.

5. **Octo + Snacks GitHub pickers**
   - Snacks finds issues and PRs.
   - Octo edits/reviews them.
   - Keep Octo only if you use in-Neovim GitHub interaction beyond opening results.

## Bottom line

The Mini selection is already sufficient; do not add more Mini modules automatically.

The two strongest missing ecosystem fits are:

1. `nvim-lint` for ALE-style non-LSP linting.
2. `grug-far.nvim` for interactive project-wide replacement—only if native quickfix editing is insufficient.

Everything else should follow the decisions already captured in `dotfiles/TODO`.
