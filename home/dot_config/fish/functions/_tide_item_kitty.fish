set --universal tide_kitty_color 'FFD1DC'
set --universal tide_kitty_bg_color 'normal'

function _tide_item_kitty \
    --description "Tide prompt item that shows the active kitty mode"

   _tide_print_item   kitty          $tide_kitty_icon' ' n
end
