function fish_paginate \
    --description 'Paginate the current command'

    set cmd $PAGER
    or return 1

    # Use delta for ripgrep with --json.
    if string match -rq '^\s*rg\b' (commandline -j);
        and command -q delta

        set cmd delta

        if not string match -rq -- '--json\b' (commandline -j)
          commandline -j (commandline -j \
              | string replace '^\s*rg\b' 'rg --json')
        end
    end

    set pipe " &| $cmd"
    if string match -rq -- ' \n\.$' "$(commandline -j; echo .)"
        set pipe "&| $cmd"
    end
    fish_commandline_append $pipe
end
