function firstmate --description 'Launch, visit a station, aheadfull, fullstop, sail or scuttle a Firstmate vessel'
    set --local subcommand launch
    if set --query argv[1]
        switch "$argv[1]"
            case launch station spyglass aheadfull fullstop sail scuttle
                set subcommand "$argv[1]"
                set --erase argv[1]
        end
    end

    if test "$subcommand" = station
        if contains -- --help $argv; or contains -- -h $argv
            printf 'Usage: firstmate station [DIRECTORY] [QUERY ...]\n'
            return 0
        end
        __firstmate_station $argv
        return $status
    end

    set --local usage \
        'Usage: firstmate [launch] [ANCHOR] [--vessel NAME] [--] [Pi arguments...]' \
        '       firstmate station [DIRECTORY] [QUERY ...]' \
        '       firstmate spyglass [ANCHOR] [--vessel NAME]' \
        '       firstmate sail ANCHOR [--vessel NAME] [--to HARBOR | --from HARBOR | --cancel]' \
        '       firstmate aheadfull [ANCHOR] [--vessel NAME]' \
        '       firstmate fullstop ANCHOR [--vessel NAME]' \
        '       firstmate scuttle ANCHOR [--vessel NAME]'

    argparse \
        --ignore-unknown \
        --strict-longopts \
        h/help \
        'vessel=+' \
        -- $argv
    or return $status

    if set --query --function _flag_help
        printf '%s\n' $usage
        printf '\n%s%s\n' \
            'Defaults: launch anchor is the current directory; vessel is flagship. ' \
            'Use -- before literal Pi options that overlap launcher options.'
        printf '%s\n' 'aheadfull recovers workers without opening Pi; launch recovers a stopped vessel before opening Pi.'
        return 0
    end

    if not set --query argv[1]
        if contains -- "$subcommand" launch aheadfull spyglass
            set argv "$PWD"
        else
            printf '%s\n' $usage >&2
            return 2
        end
    end

    if set --query --function _flag_vessel[2]
        printf 'firstmate: launcher options must not be repeated\n' >&2
        return 2
    end

    if contains -- "$subcommand" aheadfull fullstop scuttle spyglass; and set --query argv[2]
        printf 'firstmate: %s does not accept extra arguments\n' "$subcommand" >&2
        return 2
    end
    set --local target --anchor "$argv[1]"
    set --erase argv[1]
    if set --query --function _flag_vessel
        set --append target --vessel "$_flag_vessel"
    end

    if test "$subcommand" = spyglass
        __firstmate_spyglass "$target[2]" "$_flag_vessel"
        return $status
    end

    set --local core (__firstmate_core)
    if not test -x "$core/bin/fm-anchor.sh"
        printf 'firstmate: this firstmate version is missing fm-anchor.sh\n' >&2
        return 1
    end

    set --local --export PATH $PATH
    if test -d "$core/.tools/node_modules/.bin"
        set --prepend PATH "$core/.tools/node_modules/.bin"
    end

    if test "$subcommand" = fullstop
        command "$core/bin/fm-anchor.sh" fullstop $target >/dev/null
        return $status
    end

    if test "$subcommand" = sail
        command "$core/bin/fm-anchor.sh" "$subcommand" $target $argv >/dev/null
        return $status
    end

    if test "$subcommand" = scuttle
        command "$core/bin/fm-anchor.sh" scuttle $target --interactive $argv >/dev/null
        or return $status
        printf '%s%s\n' \
            'Local vessel scuttled; other vessels, outside repositories ' \
            'and other harbors were not removed.'
        return 0
    end

    set --local tools tmux nono
    if test "$subcommand" = launch
        set --append tools pi
    end
    for tool in $tools
        if not command --query "$tool"
            printf 'firstmate: required tool is missing: %s\n' "$tool" >&2
            return 1
        end
    end

    set --local anchor (path resolve -- "$target[2]")
    set --local vessel_name flagship
    if set --query --function _flag_vessel
        set vessel_name "$_flag_vessel"
    end
    set --local vessel "$anchor/.firstmate/$vessel_name"
    set --local sandbox nono run \
        --strict-broker-path \
        --profile firstmate \
        --workdir "$core" \
        --read "$core" \
        --allow "$vessel" \
        --allow-file "$anchor/.firstmate/$vessel_name.lock" \
        --read-file "$anchor/.firstmate/$vessel_name.json" \
        --read "$anchor/.firstmate/.agents" \
        --

    if test "$subcommand" = aheadfull
        command $sandbox "$core/bin/fm-anchor.sh" resume $target
        return $status
    end

    command "$core/bin/fm-anchor.sh" open $target --agent pi -- \
        $sandbox "$core/bin/fm-anchor.sh" resume $target --if-pending -- \
        pi --approve --session-dir "$vessel/pi/primary" --continue --name captain $argv
end
