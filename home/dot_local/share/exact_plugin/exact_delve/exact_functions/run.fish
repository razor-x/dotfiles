function run \
    --description 'Run a file or stdin with an appropriate interpreter'

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
        echo 'usage: run [(-e | --extension) EXT] FILE'
        echo '       COMMAND | run (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | run (-e | --extension) EXT'
        return 1
    end

    if test (count $argv) -eq 1
        set --function file $argv[1]

        if not test -f "$file"
            echo "run: no file exists named $file"
            return 1
        end

        if not set --query --function extension
            set --function extension (path extension $file)
        end
    end

    if test -z "$extension"
        echo "run: cannot run files missing a file extension: $file"
        echo "use 'run -e EXT FILE' to run this file"
        return 1
    end

    set --function tmp_extensions \
        .c \
        .go

    if not $read_from_file; and contains $extension $tmp_extensions
        set --function file (mktemp --suffix $extension)
        cat > $file
    end

    switch $extension
        case .bash .sh
            set --function cmd bash
            if $read_from_file
                set --append cmd $file
            end
        case .zsh
            set --function cmd zsh
            if $read_from_file
                set --append cmd $file
            end
        case .c
            set --function cmd (path change-extension '' $file)
            clang -o $cmd $file
        case .fish
            set --function cmd fish
            if $read_from_file
                set --append cmd $file
            end
        case .go
            set --function cmd go run $file
        case .js .jsx .ts .tsx
            set --function cmd bun run
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd -
            end
        case .lua
            set --function cmd lua
            if $read_from_file
                set --append cmd $file
            end
        case .py
            set --function cmd python
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd -
            end
        case .rb
            set --function cmd ruby
            if $read_from_file
                set --append cmd $file
            end
        case '*'
            echo "run: no runner available for $extension files"
            return 2
    end

    $cmd
end
