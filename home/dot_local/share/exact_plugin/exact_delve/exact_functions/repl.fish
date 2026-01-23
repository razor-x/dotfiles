function repl \
    --description 'Open an interactive REPL for the given language; loads the specified file before starting if provided'

    if test (count $argv) -ne 1
        echo 'usage: repl [EXT | FILE]'
        return 1
    end

    set --function extension (path extension $argv[1])

    if test -n "$extension"
        set --function file $argv[1]
        set --function read_from_file true

        if not test -f "$file"
            echo "repl: no file exists named $file"
            return 1
        end
    else
        set --function read_from_file false
        if not string match --quiet '.*' $argv[1]
            set --function extension .$argv[1]
        else
            set --function extension $argv[1]
        end
    end

    set --function file_unsupported_message \
        "repl: loading a file into a $extension REPL is not supported"

    switch $extension
        case .bash .sh .zsh
            set --function cmd (string sub --start 2 $extension) -i
            if $read_from_file
                echo $file_unsupported_message
                return 2
            end
        case .clj
            set --function cmd lein repl
            if $read_from_file
                echo $file_unsupported_message
                return 2
            end
        case .fish
            set --function cmd fish --interactive
            if $read_from_file
                set --append cmd --init-command "source $file"
            end
        case .js .ts
            set --function cmd deno repl
            if $read_from_file
                set --append cmd --eval-file $file
            end
        case .lua
            set --function cmd lua
            if $read_from_file
                set --append cmd -i $file
            end
        case .php
            set --function cmd php --interactive
            if $read_from_file
                echo $file_unsupported_message
                return 2
            end
        case .py
            set --function cmd bpython --interactive
            if $read_from_file
                set --append cmd $file
            end
        case .rb
            set --function cmd pry
            if $read_from_file
                if not string match --quiet '.*' $file;
                    or not string match --quiet '/*' $file
                    set --function file "./$file"
                end
                set --append cmd --require $file
            end
        case '*'
            echo "repl: no REPL available for $extension files"
            return 2
    end

    $cmd
end
