function down-line-or-continuation \
    --description 'Move down if there is a line below, otherwise add line continuation'

    set --function cursor (commandline --cursor)
    set --function buffer (commandline --current-buffer | string collect)
    set --function len (string length -- $buffer)

    if test $cursor -lt $len
        commandline --function down-line
    else
        if not string match --quiet '* \\' -- $buffer
            commandline --insert ' \\'
        end
        commandline --insert \n
    end
end
