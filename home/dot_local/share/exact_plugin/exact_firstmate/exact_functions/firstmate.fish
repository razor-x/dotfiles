function firstmate --description 'Launch, sail, cancel sailing or scuttle a named Firstmate vessel'
    set --local usage \
        'Usage: firstmate ANCHOR [--vessel NAME] [sail [--to HARBOR | --from HARBOR | --cancel] | --sail-to HARBOR | --scuttle | Pi arguments...]'

    argparse \
        --ignore-unknown \
        --strict-longopts \
        --exclusive sail-to,scuttle \
        h/help \
        'vessel=' \
        'sail-to=' \
        scuttle \
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

    if set --query --function _flag_vessel[2]; or set --query --function _flag_sail_to[2]; or set --query --function _flag_scuttle[2]
        printf 'firstmate: launcher options must not be repeated\n' >&2
        return 2
    end

    if set --query --function _flag_sail_to; or set --query --function _flag_scuttle
        if set --query argv[2]
            printf 'firstmate: sailing or scuttling cannot be combined with Pi arguments\n' >&2
            return 2
        end
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

    if set --query --function _flag_sail_to
        command "$core/bin/fm-anchor.sh" sail $target --to "$_flag_sail_to" $argv >/dev/null
        or return $status
        printf 'Vessel sailed to %s.\n' "$_flag_sail_to"
        return 0
    end

    if set --query argv[1]; and test "$argv[1]" = sail
        set --erase argv[1]
        command "$core/bin/fm-anchor.sh" sail $target $argv >/dev/null
        return $status
    end

    if set --query --function _flag_scuttle
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
