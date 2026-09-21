# Neovim word tools

Status: agreed behavior; dictionary backend and picker details require evaluation.
The local/global spellfile implementation is on a review branch. This document
also specifies the remaining spellfile pickers and future dictionary tools.

## Goals

Make `z` the word-editing namespace. Keep three independent capabilities:

1. Native spelling and personal/project word lists.
1. Dictionary definitions and headword search.
1. Synonym/antonym selection and replacement.

Spellfile management must work without a definition or thesaurus backend.

## Keymap contract

| Mapping       | Action                                                              |
| ------------- | ------------------------------------------------------------------- |
| `zz`          | Smart suggestions: misspelled word → spelling; otherwise → synonyms |
| `z=`          | Always spelling suggestions                                         |
| `zs`          | Always synonyms                                                     |
| `za`          | Antonyms                                                            |
| `zk`          | Definition of the current word                                      |
| `zd`          | Dictionary headword search picker                                   |
| `zg`          | Add word to global spellfile                                        |
| `zl`          | Add word to local spellfile                                         |
| `zug`         | Remove word from global spellfile                                   |
| `zul`         | Remove word from local spellfile                                    |
| `zG`          | Global spellfile management picker                                  |
| `zL`          | Local spellfile management picker                                   |
| `zc…` / `zC…` | Existing case conversion mappings                                   |

- Keep `K` unchanged; no dictionary fallback.
- When `zz` lands, remove the `<Leader>z` spelling alias and return it to the
  available keymap pool, unassigned.
- Do not add `zj`/`zk` spell-navigation aliases; use native `]s`/`[s`.
- Superseded proposals: `zt` for synonyms and `zD` for spellfile management.
- Reclaim conflicting native `z` actions intentionally, update WhichKey hints,
  and verify existing fold/viewport alternatives and terminal chord conflicts.

## Native spelling and custom dictionaries

### Architecture and language

- Use Neovim's native spell engine, not an external aspell/hunspell backend.
- Implement dictionary lifecycle in `config.spelling`, loaded by a host plugin
  spec. Keep helpers as `M` methods after primary declarations.
- Preserve native `spelllang` behavior. Do not restore `$VIM_LANG`, hard-code a
  language, or add custom content-language detection.
- Respect existing spell toggles. Keep spell disabled in terminal windows.
- Skip discovery for unnamed, URI, terminal, and other special buffers.

### Storage and discovery

- Global source: `home/dot_config/exact_nvim/spell/words.utf-8.add` in this repo.
- In managed installations, write directly to that source via
  `dotfiles.config_dir`; no manual copy-back from the installed configuration.
- Standalone fallback: `stdpath('config')/spell/words.utf-8.add`.
- Global words remain available for manual Git review and commit. Never commit
  automatically.
- Local source: `.spellfile.utf-8.add`.
- Search from the current file's directory upward, including and stopping at
  the nearest Git root. Support `.git` files as well as directories.
- Nearest local spellfile wins. Outside Git, check only the file's directory.
- Load both local and global dictionaries. Refresh on buffer entry and file
  identity changes, clearing obsolete buffer-local spellfile paths.
- Native spellfiles hold words/flags and comments, not structured definitions.
  Do not turn them into glossaries or add definition metadata.

### Add, remove, and create

- `zg`/`zug` always target global; `zl`/`zul` always target local. Never silently
  fall back from one target to the other.
- `zl` remains available without an existing local dictionary. Prompt with the
  intended path before creating one: `Create <path>? [y/N]`.
- Creation target: Git root, or current file's directory outside Git.
- No, Escape, or dismissal cancels without adding the word anywhere.
- Avoid duplicate additions and preserve unrelated entries/comments/flags.
- After `zul`, ignore blank/comment-only lines when checking for emptiness.
- If empty, prompt: `Local spellfile is empty. Remove <path>? [y/N]`.
- Yes deletes the `.add` and generated `.spl` and refreshes affected buffers.
- No/cancel preserves the empty `.add`, without retaining stale compiled words.
- Never automatically delete the global dictionary.
- `:Mklocalspell` explicitly creates or recompiles the applicable local file,
  activates it, enables spelling in the current window, and reports its path.
  Existing local files are preserved rather than overwritten.
- Invalid buffers and filesystem failures must produce clear errors.

### Compiled dictionaries

- Commit `.add` text files only; `.add.spl` files are generated artifacts.
- Compile on loading when `.spl` is missing or older than `.add`.
- Recompile immediately after additions/removals, including picker mutations.
- Refresh affected buffers after edits/deletion so loaded dictionaries agree.
- No chezmoi compilation hook: first applicable Neovim load after installation
  or pulling changes performs the same freshness check.
- Ignore `*.add.spl` in managed global Git, fd, and ripgrep ignore files.
- Exclude `.config/nvim/spell/*.spl` from chezmoi management too.

## Spellfile management pickers

These belong to the local/global spellfile feature, not the dictionary backend.

- `zG` lists global custom entries; `zL` lists the active local custom entries.
- Show the source path and distinguish spelling flags where present.
- Support text filtering and single/multiple selection for removal.
- Enter opens the selected entry in its `.add` source file.
- A separate, clearly labeled remove action deletes selected entries from that
  source, preserving unselected content.
- Batch removal rebuilds each affected dictionary once and uses the same empty
  local dictionary cleanup prompt as `zul`.
- Missing files/empty results are reported without creating files merely to
  browse them. Global dictionary files are never removed by the picker.
- No definition backend or preview lookup is required.
- Exact picker removal key and presentation remain implementation decisions.

## Smart spelling and replacement

- Normal `zz` uses the native spell checker with active languages and custom
  dictionaries to choose spelling or synonyms for the word under the cursor.
- No word means no action. A spelling lookup with no suggestions reports that;
  it must not silently switch to synonyms.
- Visual `zz` always requests synonyms for the selection, including phrases.
- Explicit synonym/antonym actions support current word or visual selection.
- Keep the existing spelling-menu conveniences: `j/k/l` select suggestions
  1/2/3, with the suggestion words as labels and numeric choices still usable.
- The spelling menu's `z` means keep the current word, not add to a dictionary.
  Show and allow it only for already-valid spelling, first in the list, labeled
  with the word itself. Then show `j/k/l`, followed by remaining suggestions.
- For synonym/antonym replacement, Enter on a result is the confirmation; do
  not add a second confirmation dialog.
- Navigating results only changes the preview. Escape leaves text unchanged.
- Replacement is one undo step and preserves straightforward capitalization.
  Do not promise grammatical inflection or guess transformations for mixed case.
- Missing backend/results/errors leave text unchanged and explain the problem.

## Definitions and dictionary search

### `zk`: definition

Read-only lookup for the current word, or selected phrase. Show meanings, parts
of speech, pronunciation, and examples when supplied by the backend. Missing
fields are omitted; do not invent data. Leave `K` and LSP hover untouched.

### `zd`: headword search picker

Search the actual dictionary vocabulary, not the user's spellfiles.

- Type to find headwords using the backend's supported matching strategies.
- Highlight a result to preview definitions; Enter opens the full definition.
- A separate explicit action may insert/replace with that word, following the
  same replacement safety rules. Enter itself is read-only.
- For a DICT/dictd backend, MATCH supplies candidates and DEFINE supplies
  definitions. Discover supported databases/strategies instead of assuming
  every server supports prefix or approximate matching.
- Headword matching is not full-text search within definition bodies.
- Debounce/cancel obsolete interactive lookups; stale responses must not
  overwrite the latest query/preview.

## Synonyms and antonyms

- `zs` and `za` are separate entry points/pickers; users need not filter mixed
  synonym/antonym results.
- Prefer grouping by backend-provided sense and part of speech. For “light”,
  distinguish low weight from illumination.
- Use nonselectable section headings if the picker supports them cleanly;
  otherwise put sense labels alongside selectable results.
- Show definitions/examples in the preview to guide replacement.
- Do not infer senses from a flat list or assume all words are interchangeable.
- Antonyms, senses, and phrase support depend on the chosen data source and must
  be evaluated explicitly; a DICT server alone does not guarantee these fields.

## Backend decision gate

Before implementation of lookup tools:

1. Evaluate data quality, licensing, supported languages, phrase handling,
   definitions/examples, synonym senses, and antonym coverage.
1. Prefer local dictionary data or a local dictd service. Online lookups must be
   explicit, never a silent fallback that sends editor text externally.
1. Decide whether dictionary and thesaurus need separate sources; assess WordNet
   as a candidate rather than assuming it satisfies every requirement.
1. Reuse existing picker infrastructure or a suitable existing Neovim plugin
   after selecting the data source. Avoid duplicate spelling engines.
1. Record chosen backend, installation requirements, offline/error behavior,
   and remaining limitations before coding the lookup integration.

Translation, grammar/rephrasing, custom glossaries, and dedicated etymology
workflows are out of scope. Pronunciation/examples may accompany definitions.

## Verification and delivery

- Review the existing spelling branch against this contract before extending it.
- Add focused headless coverage for discovery boundaries, dictionary isolation,
  native language preservation, terminal behavior, compilation freshness,
  cancellation, deletion cleanup, and source-repo versus standalone storage.
- Picker tests cover single/batch removal and preserving unselected entries.
- Lookup tests cover smart routing, empty results, cancellation, stale responses,
  read-only previews, replacement range/capitalization, and single-step undo.
- Update `doc/dotfiles.txt`, WhichKey descriptions, and TODO alongside mappings.
- Run repository formatting and checks; distinguish these from actual manual
  picker/UI verification. No lookup implementation is authorized by this spec
  alone while backend selection remains open.
