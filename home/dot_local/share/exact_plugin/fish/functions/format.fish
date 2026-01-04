function format \
    --description 'Format a file or stdin with an appropriate code formatter; writes in-place unless piped'

    argparse 'e/extension=' -- $argv
    or return

    if isatty stdout
        set --function use_stdout false
    else
        set --function use_stdout true
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
            echo "format: using -e/--extension requires input from stdin"
            return 1
        end
    else if test (count $argv) -eq 1
        set --function file $argv[1]

        if not test -e "$file"
            echo "format: no file exists named $file"
            return 1
        end

        set --function type (path extension $file)
        set --function use_stdin false
    else
        echo 'usage: format FILE'
        echo '       COMMAND | format (-e | --extension) EXT'
        return 1
    end

    if test -z "$type"
        echo "format: cannot format files missing a file extension: $file"
        return 1
    end

    switch $type
        case .fish
            set --local cmd fish_indent
            if not $use_stdout
                set --append cmd --write
            end
            if not $use_stdin
                set --append cmd $file
            end
            $cmd
        case .js .jsx .ts .tsx
            set --local cmd prettier --single-quote --jsx-single-quote --no-semi
            if not $use_stdout
                set --append cmd --write
            end
            if not $use_stdin
                set --append cmd $file
            else
                set --append cmd --parser typescript
            end
            $cmd
        case '*'
            echo "Error: no formatter available for $type files"
            return 2
    end
end
