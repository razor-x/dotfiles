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
