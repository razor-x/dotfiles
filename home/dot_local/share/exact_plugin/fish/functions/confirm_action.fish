function confirm_action \
    --argument-names message default_action \
    --description 'Prompt user for confirmation'

    if test "$default_action" = y
        set --function prompt '[Y/n]'
        set --function default_result 0
    else
        set --function prompt '[y/N]'
        set --function default_result 1
    end

    read --prompt-str "$message $prompt " --nchars 1 confirm
    echo

    switch $confirm
        case ''
            return $default_result
        case Y y
            return 0
        case N n
            return 1
    end
end
