function pipe_to_filter \
    --description 'Filter the current command'

    if type --query rg
        set --function cmd rg
    else
        set --function cmd grep
    end

    set --function pipe " | $cmd"
    if string match --regex --quiet -- ' \n\.$' "(commandline --current-job; echo .)"
        set --function pipe "| $cmd "
    end
    fish_commandline_append $pipe
    commandline --function end-of-line
end
