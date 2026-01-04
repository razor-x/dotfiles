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
        if not string match --quiet '.*' $_flag_extension
            set --function extension .$_flag_extension
        else
            set --function extension $_flag_extension
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

        set --function extension (path extension $file)
        set --function use_stdin false
    else
        echo 'usage: format FILE'
        echo '       COMMAND | format (-e | --extension) EXT'
        return 1
    end

    if test -z "$extension"
        echo "format: cannot format files missing a file extension: $file"
        return 1
    end

    if $use_stdout; or $use_stdin
        set --function write_to_file false
    else
        set --function write_to_file true
    end

    if $use_stdin
        set --function read_from_file false
    else
        set --function read_from_file true
    end

    switch $extension
        case .fish
            set --function cmd fish_indent
            if $write_to_file
                set --append cmd --write
            end
            if $read_from_file
                set --append cmd $file
            end
        case .go
            set --function cmd gofmt
            if $write_to_file
                set --append cmd -w
            end
            if $read_from_file
                set --append cmd $file
            end
        case .js .jsx .ts .tsx
            set --function cmd prettier \
                --single-quote --jsx-single-quote --no-semi \
                --config-precedence file-override
            if $write_to_file
                set --append cmd --write
            end
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --parser extension
            end
        case '*'
            echo "format: no formatter available for $extension files"
            return 2
    end

    $cmd
end
