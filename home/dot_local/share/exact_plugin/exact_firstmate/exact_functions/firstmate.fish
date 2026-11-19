function firstmate --description 'Launch, visit a station, sail or scuttle a Firstmate vessel'
    set --local subcommand launch
    if set --query argv[1]
        switch "$argv[1]"
            case launch station sail scuttle
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
        'Usage: firstmate [launch] ANCHOR [--vessel NAME] [--] [Pi arguments...]' \
        '       firstmate station [DIRECTORY] [QUERY ...]' \
        '       firstmate sail ANCHOR [--vessel NAME] [--to HARBOR | --from HARBOR | --cancel]' \
        '       firstmate scuttle ANCHOR [--vessel NAME]'

    argparse \
        --ignore-unknown \
        --strict-longopts \
        h/help \
        'vessel=+' \
        -- $argv
    or return $status

    if set --query --function _flag_help
        printf '%s\n%s\n' "$usage" 'Default vessel: flagship. Use -- before literal Pi options that overlap launcher options.'
        return 0
    end

    if not set --query argv[1]
        printf '%s\n' "$usage" >&2
        return 2
    end

    if set --query --function _flag_vessel[2]
        printf 'firstmate: launcher options must not be repeated\n' >&2
        return 2
    end

    if test "$subcommand" = scuttle; and set --query argv[2]
        printf 'firstmate: scuttling does not accept extra arguments\n' >&2
        return 2
    end
    set --local target --anchor "$argv[1]"
    set --erase argv[1]
    if set --query --function _flag_vessel
        set --append target --vessel "$_flag_vessel"
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

    if test "$subcommand" = sail
        command "$core/bin/fm-anchor.sh" sail $target $argv >/dev/null
        return $status
    end

    if test "$subcommand" = scuttle
        command "$core/bin/fm-anchor.sh" scuttle $target --interactive $argv >/dev/null
        or return $status
        printf 'Local vessel scuttled; other vessels, outside repositories and other harbors were not removed.\n'
        return 0
    end

    for tool in pi tmux nono
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

    command "$core/bin/fm-anchor.sh" open $target --agent pi -- \
        nono run \
        --strict-broker-path \
        --profile firstmate \
        --workdir "$core" \
        --read "$core" \
        --allow "$vessel" \
        --allow-file "$anchor/.firstmate/$vessel_name.lock" \
        --read-file "$anchor/.firstmate/$vessel_name.json" -- \
        pi --approve --session-dir "$vessel/pi/primary" --continue --name captain $argv
end
