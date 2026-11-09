function wget \
    --wraps wget \
    --description 'Alias wget to use a custom hsts cache file location'

    if set --query XDG_DATA_HOME; and test -n "$XDG_DATA_HOME"
        command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
    else
        command wget $argv
    end
end
