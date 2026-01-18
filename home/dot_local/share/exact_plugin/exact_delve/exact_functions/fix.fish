function fix \
    --description 'Fix linter issues in a file with an appropriate code linter'

    argparse 'e/extension=' -- $argv
    or return

    if set --query --function _flag_extension
        if not string match --quiet '.*' $_flag_extension
            set --function extension .$_flag_extension
        else
            set --function extension $_flag_extension
        end
    end

    if test (count $argv) -ne 1
        echo 'usage: fix [(-e | --extension) EXT] FILE'
        return 1
    end

    set --function file $argv[1]

    if not test -f "$file"
        echo "fix: no file exists named $file"
        return 1
    end

    if not set --query --function extension
        set --function extension (path extension $file)
    end

    if test -z "$extension"
        echo "fix: cannot fix files missing a file extension: $file"
        echo "use 'fix -e EXT FILE' to fix this file"
        return 1
    end

    # TODO: Update usage and allow stdin support
    # TODO: if $read_from_file but not $write_to_file don't --write

    switch $extension
        case .c
            set --function cmd clang-tidy --fix-errors $file --
        case .go
            set --function cmd golangci-lint run --fix $file
        case .py
            set --function cmd ruff check --fix $file
        case .rb
            set --function cmd rubocop --enable-pending-cops --lint --autocorrect $file
        case .js .jsx .ts .tsx .json .css .html
            set --function cmd biome lint --write $file
        case '*'
            echo "fix: no fixer available for $extension files"
            return 2
    end

    $cmd
end
