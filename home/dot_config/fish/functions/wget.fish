function wget \
    --wraps 'wget' \
    --description 'Alias wget to use a custom hsts cache file location'

    command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
end
