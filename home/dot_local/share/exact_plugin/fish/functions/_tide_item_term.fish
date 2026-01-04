function _tide_item_term \
    --description "Tide prompt item that shows which terminal is running"

    set --function linux_icon '󰌽'
    set --function kitty_icon '󰄛'

    if test "$TERM" = linux
        _tide_print_item term $linux_icon
    end

    if test "$TERM" = xterm-kitty
        _tide_print_item term $kitty_icon
    end
end
