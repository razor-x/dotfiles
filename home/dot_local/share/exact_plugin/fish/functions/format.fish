function format \
    --argument-names file \
    --description 'Format a file with an appropriate code formatter; writes in-place unless piped'

    set --function type (path extension $file)

    # Check if stdout is a TTY (not being piped)
    if isatty stdout
        set --function write_flag --write
    else
        set --function write_flag
    end

    switch $type
        case .js .jsx .ts .tsx
            prettier \
                --single-quote \
                --jsx-single-quote \
                --no-semi \
                $write_flag \
                $file
        case '*'
            echo "No formatter available for $type file extension"
    end
end
