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
    set --function basename (path basename $output)

    switch $extension
        case .c
            set --function cmd clang -o $output $file
        case .go
            set --function cmd go build -o $output $file
        case .js .ts
            bun build \
                --target browser \
                --outfile "$output.dist.js" \
                $file
            or return

            echo "<!DOCTYPE html>
<html>
<head>
  <title>$basename</title>
</head>
<body>
  <script type=\"module\" src=\"$basename.dist.js\"></script>
</body>
</html>" > "$output.html"
            return
        case .jsx .tsx
            bun build \
                --target browser \
                --external react \
                --external react/jsx-runtime \
                --external react/jsx-dev-runtime \
                --external react-dom \
                --outfile "$output.dist.js" \
                $file
            or return

            echo "<!DOCTYPE html>
<html>
<head>
  <title>$basename</title>
  <script type=\"importmap\">
    {
      \"imports\": {
        \"react\": \"https://esm.sh/react@18?dev\",
        \"react/jsx-runtime\": \"https://esm.sh/react@18/jsx-runtime?dev\",
        \"react/jsx-dev-runtime\": \"https://esm.sh/react@18/jsx-dev-runtime?dev\",
        \"react-dom/client\": \"https://esm.sh/react-dom@18/client?dev\"
      }
    }
  </script>
</head>
<body>
  <div id=\"root\"></div>
  <script type=\"module\" src=\"$basename.dist.js\"></script>
</body>
</html>" > "$output.html"
            return
        case '*'
            echo "compile: no compiler available for $extension files"
            return 2
    end

    $cmd
end
