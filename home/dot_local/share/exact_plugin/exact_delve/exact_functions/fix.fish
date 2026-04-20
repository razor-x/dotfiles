function fix \
    --description 'Fix linter issues in a file with an appropriate code linter'

    argparse 'e/extension=' -- $argv
    or return

    set --function arg_count (count $argv)

    if test $arg_count -eq 0
        set --function use_stdin true
    else
        set --function use_stdin false
    end

    if $use_stdin
        set --function read_from_file false
        set --function write_to_file false
    else
        set --function read_from_file true
        set --function write_to_file true
    end

    if set --query --function _flag_extension
        if not string match --quiet '.*' $_flag_extension
            set --function extension .$_flag_extension
        else
            set --function extension $_flag_extension
        end
    end

    if test $arg_count -gt 1
        echo 'usage: fix [(-e | --extension) EXT] FILE'
        echo '       COMMAND | fix (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and isatty stdin
        echo 'usage: fix [(-e | --extension) EXT] FILE'
        echo '       COMMAND | fix (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | fix (-e | --extension) EXT'
        return 1
    end

    if test $arg_count -eq 1
        set --function file $argv[1]

        if not test -f "$file"
            echo "fix: no file exists named $file"
            return 1
        end

        if not set --query --function extension
            set --function extension (path extension $file)
        end
    end

    if test -z "$extension"
        echo "fix: cannot fix files missing a file extension: $file"
        echo "use 'fix -e EXT FILE' to fix this file"
        return 1
    end

    set --function tmp_extensions \
        .go \
        .js \
        .jsx \
        .ts \
        .tsx \
        .css \
        .php \
        .py \
        .rb

    if not $read_from_file; and contains $extension $tmp_extensions
        set --function file (mktemp --suffix $extension)
        cat > "$file"
    end

    switch $extension
        case .go
            set --function cmd golangci-lint run --fix $file
        case .js .jsx .ts .tsx .css
            set --function cmd biome lint --write $file
        case .php
            set --function cmd mago lint --fix $file
        case .py
            set --function cmd ruff check --fix $file
        case .rb
            set --function cmd rubocop --enable-pending-cops --lint --autocorrect $file
        case '*'
            echo "fix: no fixer available for $extension files"
            return 2
    end

    $cmd

    if not $write_to_file
        cat "$file"
    end
end
