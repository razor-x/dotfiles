function format \
    --description 'Format a file with an appropriate code formatter; writes in-place unless piped'

    argparse 'e/extension=' -- $argv
    or return

    if isatty stdout
        set --function use_stdout true
    else
        set --function use_stdout false
    end

    if set --query _flag_extension
        set --function type $_flag_extension

        # Normalize the extension to start with a dot.
        if not string match --quiet '.*' $type
            set type .$type
        end

        if not isatty stdin
            set --function use_stdin true
        else
            echo "Error: using -e/--extension requires input from stdin"
            return 1
        end
    else if test (count $argv) -eq 1
        set --function type (path extension $argv[1])
        set --function file $argv[1]
        set --function use_stdin false
    else
        echo "Usage: format FILE or cat FILE | format --extension EXT"
        return 1
    end

    switch $type
        case .js .jsx .ts .tsx
            set --local cmd prettier --single-quote --jsx-single-quote --no-semi
            if $use_stdin
                set --append cmd --parser typescript
            else
                set --append cmd $file
            end
            if $use_stdout
                set --append cmd --write
            end
            $cmd
        case '*'
            echo "No formatter available for $type file extension"
            return 2
    end
end
