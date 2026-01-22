function format \
    --description 'Format a file or stdin with an appropriate code formatter; writes in-place unless piped'

    argparse 'e/extension=' -- $argv
    or return

    if isatty stdin
        set --function use_stdin false
    else
        set --function use_stdin true
    end

    if isatty stdout
        set --function use_stdout false
    else
        set --function use_stdout true
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
        echo 'usage: format [(-e | --extension) EXT] FILE'
        echo '       COMMAND | format (-e | --extension) EXT'
        return 1
    end

    if $use_stdin; and not set --query --function extension
        echo 'usage: COMMAND | format (-e | --extension) EXT'
        return 1
    end

    if test (count $argv) -eq 1
        set --function file $argv[1]

        if not test -f "$file"
            echo "format: no file exists named $file"
            return 1
        end

        if not set --query --function extension
            set --function extension (path extension $file)
        end
    end

    if test -z "$extension"
        echo "format: cannot format files missing a file extension: $file"
        echo "use 'format -e EXT FILE' to format this file"
        return 1
    end

    set --function tmp_extensions \
        .php

    if not $read_from_file; and contains $extension $tmp_extensions
        set --function file (mktemp --suffix $extension)
        cat > $file
    end

    # TODO: if $read_from_file but not $write_to_file don't --write

    switch $extension
        case .bash .sh .zsh
            set --function cmd shfmt
            if $write_to_file
                set --append cmd --write
            end
            if $read_from_file
                set --append cmd $file
            end
        case .c
            set --function cmd clang-format
            if $write_to_file
                set --append cmd -i
            end
            if $read_from_file
                set --append cmd $file
            end
        case .clj
            set --function cmd cljfmt fix
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd -
            end
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
        case .js .jsx .ts .tsx .json .jsonc .html .css .graphql
            set --function cmd biome format
            if not biome rage 2>/dev/null \
                | string match --quiet '*Status:*Loaded successfully*'
                set --append cmd \
                    --indent-style=space \
                    --jsx-quote-style=single \
                    --semicolons=as-needed \
                    --javascript-formatter-quote-style=single \
                    --html-formatter-enabled=true
            end
            if $write_to_file
                set --append cmd --write
            end
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --stdin-file-path "tmp.$extension"
            end
        case .md
            set --function cmd mdformat
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd -
            end
        case .yaml .yml
            set --function cmd yq --prettyPrint
            if $read_from_file
                set --append cmd --inplace $file
            end
        case .lua
            set --function cmd stylua
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --stdin-filepath tmp.lua -
            end
        case .php
            set --function cmd mago format $file
            if not $read_from_file
                # TODO: Print formatted tmp file.
                # set --append cmd " && cat $file"
                echo "format: stdin for $extension REPL is not supported"
                return 2
            end
        case .py
            set --function cmd ruff format
            if $read_from_file
                set --append cmd $file
                if not $write_to_file
                    set --append cmd -
                end
            else
                set --append cmd --stdin-filename tmp.py -
            end
        case .rb
            set --function cmd rubocop --enable-pending-cops --fix-layout --autocorrect
            if $read_from_file
                set --append cmd $file
            else
                set --append cmd --stdin tmp.rb
            end
        case '*'
            echo "format: no formatter available for $extension files"
            return 2
    end

    $cmd
end
