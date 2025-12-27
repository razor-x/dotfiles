set --global tide_kitty_color 'FFD1DC'
set --global tide_kitty_bg_color 'normal'
set --global tide_kitty_icon '󰄛'

function _tide_item_kitty \
    --description "Tide prompt item that shows if running inside kitty terminal"

    if test "$TERM" != xterm-kitty
        return
    end

    _tide_print_item 'kitty' $tide_kitty_icon
end
