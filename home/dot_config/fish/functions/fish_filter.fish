function fish_filter \
    --description 'Filter the current command'

    if type --query rg
        set cmd rg
    else
        set cmd grep
    end

    set pipe " | $cmd"
    if string match --regex --quiet -- ' \n\.$' "$(commandline --current-job; echo .)"
        set pipe "| $cmd "
    end
    fish_commandline_append $pipe
    commandline --function end-of-line
end
