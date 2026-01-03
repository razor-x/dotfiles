function _tide_item_kitty \
    --description "Tide prompt item that shows if running inside kitty terminal"
    set --query tide_kitty_icon[1]
    or set tide_kitty_icon '󰄛'

    if test "$TERM" != xterm-kitty
        return
    end

    _tide_print_item 'kitty' $tide_kitty_icon
end
