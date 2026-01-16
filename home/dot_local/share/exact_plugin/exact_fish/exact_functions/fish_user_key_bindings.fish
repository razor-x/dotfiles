function fish_user_key_bindings \
    --description 'Fish automatically executes this function after setting all preset bindings'

    # Remove escape delay since alt bindings are not used.
    set --global fish_escape_delay_ms 10

    # Use hybrid Emacs-Vi bindings.
    fish_hybrid_key_bindings

    # Erase all Ctrl and Alt insert mode bindings.
    bind \
        | grep --extended-regexp --no-ignore-case 'bind --preset (-M \w+ )?(ctrl|alt|shift)' \
        # Keep ctrl-space which inserts a literal space without expanding abbreviations.
        # Pressing j then space on home row mods will often be read as ctrl-space and thus must work like space.
        | grep --invert-match ctrl-space \
        # Keep escape (ctrl-[) which toggles normal and insert mode.
        | grep --invert-match 'ctrl-\[' \
        | string replace --regex '^bind\s+(.*?)((ctrl|alt|shift)-\S+)\s.*' 'bind --erase $1$2' \
        | source

    # Erase arrow key bindings.
    for mode in default insert visual
        bind --erase --preset --mode $mode left
        bind --erase --preset --mode $mode right
    end

    # Configure fzf bindings.
    fzf_configure_bindings \
        --directory='ctrl-shift-space' \
        --git_log="ctrl-'" \
        --git_status='ctrl-;' \
        --history='' \
        --processes='ctrl-\\' \
        --variables='ctrl-x'

    # Edit command buffer in editor.
    bind --mode default vv edit_command_buffer
    bind --mode insert ctrl-m edit_command_buffer

    # Navigate history.
    bind --mode insert ctrl-p up-or-search
    bind --mode insert ctrl-n down-or-search

    # Navigate prompt.
    bind --erase --preset --mode insert backspace
    bind --mode insert backspace backward-char
    bind --mode insert ctrl-l forward-char
    bind --mode insert ctrl-k up-line
    bind --mode insert ctrl-j down-line-or-continuation
    bind --mode insert ctrl-f forward-word
    bind --mode insert ctrl-r backward-word-or-atuin
    bind --mode insert ctrl-shift-f forward-token
    bind --mode insert ctrl-shift-r backward-token
    bind --mode insert ctrl-a beginning-of-line-or-history-pager
    bind --mode insert ctrl-e end-of-line accept-autosuggestion

    # Delete from prompt.
    bind --mode insert ctrl-h backward-delete-char
    bind --mode insert ctrl-w backward-kill-word-or-navi
    bind --mode insert ctrl-shift-w backward-kill-token
    bind --mode insert ctrl-backspace backward-kill-path-component
    bind --mode insert shift-backspace backward-kill-line
    bind --mode insert ctrl-shift-backspace kill-whole-line
    bind --mode insert ctrl-delete kill-path-component
    bind --mode insert shift-delete kill-line
    bind --mode insert ctrl-shift-delete kill-whole-line

    # Manipulate prompt.
    bind --mode insert ctrl-z undo
    bind --mode insert ctrl-shift-z redo
    bind --mode insert ctrl-t transpose-chars
    bind --mode insert ctrl-q pipe_to_pager
    bind --mode insert ctrl-g pipe_to_filter
    bind --mode insert ctrl-c clear-commandline repaint-mode

    # Access clipboard.
    bind --mode insert ctrl-v fish_clipboard_paste
    bind --mode insert ctrl-shift-v 'commandline --insert "(fish_clipboard_paste)"'
    bind --mode insert ctrl-y 'commandline | string collect | fish_clipboard_copy'
    bind --mode insert ctrl-shift-c copy_file_to_clipboard
    bind --mode insert ctrl-comma pipe_from_clipboard
    bind --mode insert ctrl-. pipe_to_clipboard

    # Clear scrollback.
    bind --mode insert ctrl-shift-d scrollback-push

    # Get info.
    bind --mode insert ctrl-/ __fish_man_page

    # Control.
    bind --mode insert ctrl-d exit

    # Execute.
    for mode in default insert visual
        bind --mode $mode shift-enter execute-in-stack
        bind --mode $mode ctrl-enter execute-in-split
        bind --mode $mode ctrl-shift-enter execute-in-tab
    end

    # Vi default (normal) mode bindings.
    bind --mode default U redo

    # Restore bindings for ctrl-m (enter) and ctrl-i (tab) in vconsole.
    if test "$TERM" = linux
        bind --mode insert ctrl-m execute
        bind --mode insert ctrl-i complete
    end

    # UPSTREAM: Setting fifc_keybinding does not preserve tab default behavior.
    # https://github.com/gazorby/fifc/issues/57
    for mode in default insert visual
        bind --mode $mode tab complete
        bind --mode $mode shift-tab complete-and-search
    end

    # Show Git status.
    bind --mode insert ctrl-i \
        'commandline " git status"; commandline --function execute'

    # Interactively stage changes with Git.
    bind --mode insert ctrl-o \
        'commandline " git add --patch"; execute-in-stack'

    # Show diff of staged changes with Git.
    bind --mode insert ctrl-u \
        'commandline " git diff --cached"; execute-in-stack'

    # Start opencode in a new split.
    bind --mode insert ctrl-shift-o \
        'commandline " opencode"; execute-in-split'

    # TODO: Bind open keys.
    # bind --mode insert ctrl-u
    # bind --mode insert ctrl-b
end
