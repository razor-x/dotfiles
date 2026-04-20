function check \
    --description 'Check a file with an appropriate static analyzer'

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

    if test $arg_count -gt 1
        echo 'usage: check [(-e | --extension) EXT] FILE'
        echo '       COMMAND | check (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and isatty stdin
        echo 'usage: check [(-e | --extension) EXT] FILE'
        echo '       COMMAND | check (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | check (-e | --extension) EXT'
        return 1
    end

    if test $arg_count -eq 1
        set --function file $argv[1]

        if not test -f "$file"
            echo "check: no file exists named $file"
            return 1
        end

        if not set --query --function extension
            set --function extension (path extension $file)
        end
    end

    if test -z "$extension"
        echo "check: cannot check files missing a file extension: $file"
        echo "use 'check -e EXT FILE' to check this file"
        return 1
    end

    set --function tmp_extensions \
        .c \
        .go \
        .php \
        .py \
        .ts \
        .tsx

    if not $read_from_file; and contains $extension $tmp_extensions
        set --function file (mktemp --suffix $extension)
        cat > "$file"
    end

    switch $extension
        case .c
            set --function cmd clang-check $file
        case .go
            set --function cmd go vet $file
        case .php
            set --function cmd mago analyse $file
        case .py
            set --function cmd pyright $file
        case .ts .tsx
            set --function cmd tsc --noEmit
            if test $extension = .tsx
                set --append cmd --jsx react-jsx --skipLibCheck
            end
            set --append cmd $file
        case '*'
            echo "check: no checker available for $extension files"
            return 2
    end

    $cmd
end
