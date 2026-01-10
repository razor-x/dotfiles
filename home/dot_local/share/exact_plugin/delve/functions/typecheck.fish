function typecheck \
    --description 'Typecheck a file with an appropriate type checker'

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
        echo 'usage: typecheck [(-e | --extension) EXT] FILE'
        return 1
    end

    set --function file $argv[1]

    if not test -f "$file"
        echo "typecheck: no file exists named $file"
        return 1
    end

    if test -z "$extension"
        echo "typecheck: cannot typecheck files missing a file extension: $file"
        echo "use 'typecheck -e EXT FILE' to typecheck this file"
        return 1
    end

    switch $extension
        case .c
            set --function cmd clang-check $file
        case .go
            set --function cmd go vet $file
        case .ts .tsx
            set --function cmd tsc --noEmit $file
        case '*'
            echo "typecheck: no type checker available for $extension files"
            return 2
    end

    $cmd
end
