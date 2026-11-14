# Zellij 0.46.0 keybinding upgrade handoff

## Task and status

Compare the user's customized Zellij 0.43.1 unlock-first preset with the
installed Zellij 0.46.0 preset, then decide which upstream additions to adopt.
The investigation is complete; the managed Zellij configuration has not been
changed for this upgrade.

Managed source: `home/dot_config/exact_zellij/config.kdl.tmpl`.

Read repository instructions and inspect the working tree before resuming.
Do not overwrite unrelated edits.

## Maintenance requirements

The user explicitly requires:

- Surround customizations with `// -- begin customization --` and
  `// -- end customization --`.
- Keep disabled upstream bindings commented out in their original positions
  inside customization blocks rather than deleting them.
- Merge adjacent customization blocks; do not put an end marker immediately
  before another begin marker.
- Keep Zellij config comments independent of Kitty.
- Preserve intentional leader, mode-transition, navigation, resize, and Alt
  customizations unless the user approves changes.

## Saved references

All reference files are saved alongside this handoff in `docs/`:

- `zellij-0.46.0-unlock-first-reference.kdl`: fresh installed unlock-first preset.
- `zellij-0.46.0-default-reference.kdl`: fresh installed default config.
- `zellij-0.43.1-unlock-first.normalized.kdl`: old upstream keyboard preset,
  normalized for comparison.
- `zellij-0.46.0-unlock-first.normalized.kdl`: new upstream keyboard preset,
  normalized for comparison.
- `zellij-unlock-first-0.43.1-to-0.46.0.diff`: normalized upstream comparison.

## Recreate the references

Check the installed version first:

```sh
zellij --version
zellij setup --dump-keybinds unlock-first > docs/zellij-0.46.0-unlock-first-reference.kdl
zellij setup --dump-config > docs/zellij-0.46.0-default-reference.kdl
```

The fresh preset dump includes metadata, modifier placeholders, and mouse
bindings. It is not a drop-in replacement for the managed config.

Retrieve the old upstream preset implementation using GitHub CLI:

```sh
gh api \
  'repos/zellij-org/zellij/contents/default-plugins/configuration/src/presets.rs?ref=v0.43.1' \
  --jq .content | base64 --decode > /tmp/zellij-0.43.1-presets-reference.rs
```

For an upstream-to-upstream comparison:

1. Extract the first Rust raw format string in `unlock_first_keybinds`.
1. Unescape Rust's doubled braces, and resolve `{primary_modifier}` to `Ctrl`
   and `{secondary_modifier}` to `Alt`.
1. In the new dump, resolve `{primary}` to `Ctrl` and `{secondary}` to `Alt`.
1. Normalize old `Ctrl g` and new `{unlock}` to the same value, such as `Ctrl s`.
   This is comparison normalization, not an upstream binding change.
1. Compare only the `keybinds` sections, normalizing their opening headers and
   excluding new preset metadata and mouse bindings.
1. Compare those upstream differences with the managed customizations.

The findings below came from this comparison of exactly 0.43.1 and 0.46.0.
If the installed version has changed again, recheck them.

## Upstream changes

After normalizing modifiers, existing upstream keyboard assignments were
unchanged. Changes were additions and shared-mode exclusions for the new
rename-session mode.

### Pane mode

| Key       | New action                                |
| --------- | ----------------------------------------- |
| `;`       | `FocusLastPane`                           |
| `a`       | `NewFloatingPane`, then locked            |
| `Shift s` | `ToggleStackListOrientation`, then locked |
| `Shift f` | `ToggleFocusNoUiFullscreen`, then locked  |
| `Shift z` | `ToggleBars`, then locked                 |
| `u`       | `MutePane`, then locked                   |
| `g`       | `IgnorePaneOutput`, then locked           |
| `v`       | `WatchPane`, then locked                  |

### Tab mode

| Key           | New action             |
| ------------- | ---------------------- |
| `Space`       | `NextSwapLayout`       |
| `Shift Space` | `PreviousSwapLayout`   |
| `u`           | `MuteTab`, then locked |

### Scroll mode

| Key | New action                           |
| --- | ------------------------------------ |
| `[` | `ScrollToPreviousPrompt`             |
| `]` | `ScrollToNextPrompt`                 |
| `m` | `SelectCommandAtScrollPosition`      |
| `c` | `CopyLastCommandOutput`, then locked |

### Search mode

| Key | New action                      |
| --- | ------------------------------- |
| `[` | `ScrollToPreviousPrompt`        |
| `]` | `ScrollToNextPrompt`            |
| `m` | `SelectCommandAtScrollPosition` |

### Session mode

| Key     | New action                                                             |
| ------- | ---------------------------------------------------------------------- |
| `i`     | `ToggleSessionCard`, then locked                                       |
| `r`     | Enter `RenameSession`; initialize `SessionNameInput 0`                 |
| `]`     | `FocusHostSession`, then locked                                        |
| `[`     | `FocusGuestSession`, then locked                                       |
| `f`     | `ToggleHostFullscreen`, then locked                                    |
| `u`     | `MuteSession`, then locked                                             |
| `Tab`   | `ToggleSession`, then locked                                           |
| `Left`  | `GoToPreviousSession`, then locked                                     |
| `Right` | `GoToNextSession`, then locked                                         |
| `n`     | `GoToNextAttention`, then locked                                       |
| `l`     | Open `zellij:layout-manager`, floating on the focused tab, then locked |

### Rename-session mode and shared exclusions

```kdl
renamesession {
    bind "Ctrl c" "Enter" { SwitchToMode "Locked"; }
    bind "Esc" { UndoRenameSession; SwitchToMode "Session"; }
}
```

Upstream adds `renamesession` to shared exclusions for quit, unlock/lock,
escape, enter, and mode switching. If adopting this mode, review the user's
customized shared groups too, so typing a session name does not trigger actions.

## Conflicts requiring user decisions

These conflict with existing customized shared bindings:

| New binding                       | Existing customized use |
| --------------------------------- | ----------------------- |
| Pane `a`: new floating pane       | Enter tab mode          |
| Tab `Space`: next swap layout     | Enter scroll mode       |
| Scroll/search `m`: select command | Enter move mode         |
| Session `r`: rename session       | Enter resize mode       |

Specific-mode bindings may override shared bindings. Do not silently remove
existing mode transitions by copying the new preset wholesale. Review
`Shift Space` alongside the user's existing layout shortcuts as well.

## Older omissions, not new additions

These were already upstream in 0.43.1 but absent or displaced in the user's
managed config:

- Pane `s`: `NewPane "stacked"`; customized pane `s` returns to normal mode.
- Tab `s`: `ToggleActiveSyncTab`; customized shared `s` enters pane mode.
- Session `s`: launch/focus `zellij:share`.

Do not label these as new in 0.46.0. If retaining their absence during a refresh,
follow the commented-out-binding convention.

## Related configuration context

At investigation time:

- Zellij used `Ctrl s` as unlock/leader rather than upstream's `Ctrl g`.
- Custom mode transitions included `s` for pane, `a` for tab, `z` for session,
  and Space for scroll.
- Only `Alt h/j/k/l` resizing remained directly bound with Alt in
  normal/locked modes; other Alt bindings were intentionally commented out.
- `Ctrl Shift h/j/k/l` invoked `vim-zellij-navigator`, which forwarded plain
  Ctrl directional keys to Neovim.
- Neovim smart-splits detected its Zellij backend before Kitty. The Zellij-side
  navigator remained necessary; it complements the Neovim backend.
- Automatic Kitty routing was separate work using Fish's `IS_MUX` window
  variable. Do not reintroduce broad keyboard passthrough or the abandoned
  template-generated Alt mappings as part of this upgrade.

Re-read the sources before making changes; this context may have evolved.

## Next steps and validation

1. Ask the user which new actions to adopt and how to resolve the conflicts.

1. Refresh the keybind section while preserving customizations and commented
   upstream bindings.

1. Update the generated-version comment only after the refresh is complete;
   the old comment correctly records the 0.43.1 baseline until then.

1. Validate rendered KDL with an isolated temporary config:

   ```sh
   zellij --config <rendered-config> \
     --config-dir <temporary-dir> \
     --data-dir <temporary-data-dir> setup --check
   ```

   For a focused syntax check, the theme template can be replaced in the
   temporary fixture with `theme "default"`. Do not inspect or modify installed
   home configs for verification.

1. Run `git diff --check` and applicable repository checks. Earlier aggregate
   checks stopped on a missing Pi `vitest` executable; re-evaluate its current
   status and report any remaining failure.

## Scope limits

This investigation covers the unlock-first keyboard preset across the two
specified versions. It does not establish which intermediate release added
each feature, audit all mouse bindings, or compare all non-keybinding defaults.
No configuration migration or live interaction testing has been performed.
