function lint \
    --description 'Lint a file or stdin with an appropriate code linter'

    argparse 'e/extension=' -- $argv
    or return

    if isatty stdin
        set --function use_stdin false
    else
        set --function use_stdin true
    end

    if $use_stdin
        set --function read_from_file false
    else
        set --function read_from_file true
    end

    if set --query --function _flag_extension
        if not string match --quiet '.*' $_flag_extension
            set --function extension .$_flag_extension
        else
            set --function extension $_flag_extension
        end
    end

    if begin
            $use_stdin; and test (count $argv) -gt 0
        end;
        or not $use_stdin; and test (count $argv) -ne 1
        echo 'usage: lint [(-e | --extension) EXT] FILE'
        echo '       COMMAND | lint (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | lint (-e | --extension) EXT'
        return 1
    end

    if test (count $argv) -eq 1
        set --function file $argv[1]

        if not test -f "$file"
            echo "lint: no file exists named $file"
            return 1
        end

        if not set --query --function extension
            set --function extension (path extension $file)
        end
    end

    if test -z "$extension"
        echo "lint: cannot lint files missing a file extension: $file"
        echo "use 'lint -e EXT FILE' to lint this file"
        return 1
    end

    set --function stdin_unsupported_message \
        "lint: cannot lint $extension files from stdin"

    switch $extension
        case .bash .sh .zsh
            set --function cmd shellcheck
            if $read_from_file
                set --append cmd $file
            else
                echo $stdin_unsupported_message
                return 2
            end
        case .c
            set --function cmd clang-tidy
            if $read_from_file
                set --append cmd $file
            else
                echo $stdin_unsupported_message
                return 2
            end
        case .fish
            set --function cmd fish --no-execute
            if $read_from_file
                set --append cmd $file
            end
        case .go
            set --function cmd golangci-lint run
            if $read_from_file
                set --append cmd $file
            else
                echo $stdin_unsupported_message
                return 2
            end
        case .js .jsx .ts .tsx
            set --function cmd biome lint
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --stdin-file-path="tmp.$extension"
            end
        case '*'
            echo "lint: no linter available for $extension files"
            return 2
    end

    $cmd
end
