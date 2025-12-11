function fish_user_key_bindings \
    --description 'Fish automatically executes this function after setting all preset bindings'

    # Use hybrid Emacs-Vi bindings.
    fish_hybrid_key_bindings

    # Erase all Ctrl and Alt insert mode bindings.
    bind \
        | grep --extended-regexp --no-ignore-case 'bind --preset -M insert (ctrl|alt)' \
        # Keep ctrl-space which inserts a literal space without expanding abbreviations.
        | grep --invert-match 'ctrl-space' \
        # Keep escape (ctrl-[) which toggles normal and insert mode.
        | grep --invert-match 'ctrl-\[' \
        | string replace -r '^bind\s+(.*?)((ctrl|alt)-\S+)\s.*' 'bind --erase $1$2' \
        | source

    # Erase arrow key bindings.
    bind --erase left
    bind --erase shift-left
    bind --erase right
    bind --erase shift-right

    # Configure fzf bindings.
    fzf_configure_bindings \
        --directory='ctrl-i' \
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
    bind --mode insert 'ctrl-tab' _atuin_search

    # Navigate prompt.
    bind --mode insert ctrl-o forward-char
    bind --mode insert ctrl-u backward-char
    bind --mode insert ctrl-f forward-word
    bind --mode insert ctrl-r backward-word
    bind --mode insert ctrl-shift-f forward-token
    bind --mode insert ctrl-shift-r backward-token
    bind --mode insert ctrl-a beginning-of-line-or-history-pager
    bind --mode insert ctrl-e end-of-line accept-autosuggestion

    # Delete from prompt.
    bind --mode insert ctrl-b backward-delete-char
    bind --mode insert ctrl-w backward-kill-word
    bind --mode insert ctrl-shift-w backward-kill-token
    bind --mode insert ctrl-backspace backward-kill-path-component
    bind --mode insert ctrl-delete kill-line

    # Manipulate prompt.
    bind --mode insert ctrl-t transpose-chars
    bind --mode insert ctrl-q fish_paginate
    bind --mode insert ctrl-g fish_filter
    bind --mode insert ctrl-z undo
    bind --mode insert ctrl-shift-z redo

    # Access clipboard.
    bind ctrl-enter fish_clipboard_paste
    bind --mode insert ctrl-c clear-commandline repaint-mode
    bind --mode insert ctrl-v fish_clipboard_paste
    bind --mode insert ctrl-comma 'commandline -i "(fish_clipboard_paste)"'
    bind --mode insert ctrl-. fish_clipboard_pipe

    # Misc.
    bind --mode insert ctrl-/ __fish_whatis_current_token
    bind --mode visual ctrl-/ __fish_whatis_current_token
    bind --mode insert ctrl-d delete-or-exit

    # Restore bindings for ctrl-m (enter) and ctrl-i (tab) in vconsole.
    if test "$TERM" = "linux"
        bind --mode insert ctrl-m execute
        bind --mode insert ctrl-i complete
    end

    # TODO: Bind ctrl-y
end
