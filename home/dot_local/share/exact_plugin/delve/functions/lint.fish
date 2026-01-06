function lint \
    --description 'Lint a file or stdin with an appropriate code linter'

    argparse 'e/extension=' 'f/fix' -- $argv
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

    if set --query _flag_fix
        set --function fix true
    else
        set --function fix false
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
        echo 'usage: lint [(-e | --extension) EXT] [(-f | --fix)] FILE'
        echo '       COMMAND | lint (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | lint (-e | --extension) EXT'
        return 1
    end

    if test (count $argv) -eq 1
        set --function file $argv[1]

        if not test -e "$file"
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

    switch $extension
        case .fish
            if $fix
                echo "lint: -f/--fix is not supported for $extension files"
                return 2
            end
            set --function cmd fish --no-execute
            if $read_from_file
                set --append cmd $file
            end
        case .go
            set --function cmd golangci-lint run
            if $fix
                set --append cmd --fix
            end
            if $read_from_file
                set --append cmd $file
            else
                echo "lint: cannot lint $extension files from stdin"
                return 2
            end
        case .js .jsx
            set --function cmd eslint --no-config-lookup
            if $fix
                set --append cmd --fix
            end
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --stdin --stdin-filename "tmp.$extension"
            end
        case .ts .tsx
            if $fix
                echo "lint: -f/--fix is not supported for $extension files"
                return 2
            end
            set --function cmd tsc --noEmit
            if $read_from_file
                set --append cmd $file
            else
                echo "lint: cannot lint $extension files from stdin"
                return 2
            end
        case .bash .sh .zsh
            if $fix
                echo "lint: -f/--fix is not supported for $extension files"
                return 2
            end
            set --function cmd shellcheck
            if $read_from_file
                set --append cmd $file
            else
                echo "lint: cannot lint $extension files from stdin"
                return 2
            end
        case .c
            if $fix
                set --append cmd --fix-errors
            end
            set --function cmd clang-tidy
            if $read_from_file
                set --append cmd $file
            else
                echo "lint: cannot lint $extension files from stdin"
                return 2
            end
        case '*'
            echo "lint: no linter available for $extension files"
            return 2
    end

    $cmd
end
