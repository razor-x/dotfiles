function compile \
    --description 'Compile a file with an appropriate compiler; output has same name without extension'

    if test (count $argv) -ne 1
        echo 'usage: compile FILE'
        return 1
    end

    set --function file $argv[1]

    if not test -e "$file"
        echo "compile: no file exists named $file"
        return 1
    end

    set --function extension (path extension $file)

    if test -z "$extension"
        echo "compile: cannot compile files missing a file extension: $file"
        return 1
    end

    set --function output (path change-extension '' $file)

    switch $extension
        case .c
            set --function cmd clang -o $output $file
        case .go
            set --function cmd go build -o $output $file
        case .js .jsx .ts .tsx
            set --function cmd bun build \
                --target browser \
                --external react \
                --external react/jsx-runtime \
                --external react/jsx-dev-runtime \
                --external react-dom \
                --outfile "$output.dist.js" \
                $file
        case '*'
            echo "compile: no compiler available for $extension files"
            return 2
    end

    $cmd
end
