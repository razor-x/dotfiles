function _tide_item_term \
    --description 'Tide prompt item that shows which terminal is running'

    set --function linux_icon '󰌽'
    set --function kitty_icon '󰄛'

    if set --query TERM; and test "$TERM" = linux
        _tide_print_item term $linux_icon
        return
    end

    if set --query TERM; and test "$TERM" = xterm-kitty
        _tide_print_item term $kitty_icon
        return
    end
end
