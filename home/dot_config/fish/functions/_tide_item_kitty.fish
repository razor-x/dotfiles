set --universal tide_kitty_color 'FFD1DC'
set --universal tide_kitty_bg_color 'normal'

function _tide_item_kitty \
    --description "Tide prompt item that shows the active kitty mode"

    if not set -q KITTY_WINDOW_ID
        return
    end

    set mode (kitten @ ls --match id:$KITTY_WINDOW_ID \
        | jq -r '.[0].tabs[0].windows[0].user_vars.mode // "insert"')

    switch $mode
        case 'insert'
            _tide_print_item 'kitty' $tide_kitty_icon
        case 'normal'
            _tide_print_item 'kitty' $tide_kitty_icon 'n'
    end
end
