function pipe_to_pager \
    --description 'Paginate the current command'

    set --function cmd $PAGER
    or return 1

    # Use delta for ripgrep with --json.
    if string match --regex --quiet '^\s*rg\b' (commandline --current-job);
        and command --query delta

        set --function cmd delta

        if not string match --regex --quiet -- '--json\b' (commandline --current-job)
          commandline --current-job (commandline --current-job \
              | string replace '^\s*rg\b' 'rg --json')
        end
    end

    set --function pipe " &| $cmd"
    if string match --regex --quiet -- ' \n\.$' "(commandline --current-job; echo .)"
        set --function pipe "&| $cmd"
    end
    fish_commandline_append $pipe
end
