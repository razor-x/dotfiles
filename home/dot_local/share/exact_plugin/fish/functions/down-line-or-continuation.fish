function down-line-or-continuation \
    --description 'Move down if there is a line below, otherwise add line continuation'

    set --local cursor (commandline --cursor)
    set --local buffer (commandline --current-buffer | string collect)
    set --local len (string length -- $buffer)

    if test $cursor -lt $len
        commandline --function down-line
    else
        if not string match --quiet '* \\' -- $buffer
            commandline --insert ' \\'
        end
        commandline --insert \n
    end
end
