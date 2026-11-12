function firstmate --description 'Launch, sail or scuttle a named Firstmate vessel'
    if not set -q argv[1]
        printf 'Usage: firstmate ANCHOR [--vessel NAME] [--sail-to HARBOR | --scuttle | Pi arguments...]\n' >&2
        return 2
    end
    if contains -- "$argv[1]" -h --help
        printf 'Usage: firstmate ANCHOR [--vessel NAME] [--sail-to HARBOR | --scuttle | Pi arguments...]\nDefault vessel: flagship. Use -- before literal Pi options that overlap launcher options.\n'
        return 0
    end
    if test (uname -s) != Linux
        printf 'firstmate: local vessels currently require Linux\n' >&2
        return 1
    end
    set -l anchor (path resolve -- "$argv[1]")
    if not test -d "$anchor"
        printf 'firstmate: anchor must be an existing directory\n' >&2
        return 1
    end
    set -e argv[1]
    argparse --ignore-unknown --exclusive sail-to,scuttle 'vessel=' 'sail-to=' scuttle -- $argv
    or return $status
    if set -q _flag_vessel[2]; or set -q _flag_sail_to[2]; or set -q _flag_scuttle[2]
        printf 'firstmate: launcher options must not be repeated\n' >&2
        return 2
    end
    set -l vessel_name flagship
    if set -q _flag_vessel
        set vessel_name "$_flag_vessel"
    end
    if not string match --quiet --regex '\\A[a-z0-9][a-z0-9_-]{0,63}\\z' -- "$vessel_name"
        printf 'firstmate: invalid vessel name\n' >&2
        return 2
    end
    if set -q _flag_sail_to; or set -q _flag_scuttle
        if set -q argv[1]
            printf 'firstmate: sailing or scuttling cannot be combined with Pi arguments\n' >&2
            return 2
        end
    end
    set -l core (__firstmate_core)
    if not test -x "$core/bin/fm-anchor.sh"
        printf 'firstmate: install the named-vessel core first\n' >&2
        return 1
    end
    set -l vessel "$anchor/.firstmate/$vessel_name"
    set -l target --anchor "$anchor" --vessel "$vessel_name"
    set -lx PATH $PATH
    if test -d "$core/.tools/node_modules/.bin"
        set -p PATH "$core/.tools/node_modules/.bin"
    end

    if set -q _flag_sail_to
        if test -z "$_flag_sail_to"
            printf 'firstmate: a destination harbor is required\n' >&2
            return 2
        end
        command "$core/bin/fm-anchor.sh" sail $target --to "$_flag_sail_to" >/dev/null
        or return $status
        printf 'Vessel %s sailed to %s.\n' "$vessel_name" "$_flag_sail_to"
        return 0
    end
    if set -q _flag_scuttle
        printf 'Permanently delete %s, its metadata, ALL vessel repositories, uncommitted work and session history?\nType SCUTTLE to confirm: ' "$vessel" >&2
        read -l answer; or return 1
        if test "$answer" != SCUTTLE
            printf 'Scuttle cancelled.\n' >&2
            return 1
        end
        command "$core/bin/fm-anchor.sh" scuttle $target --confirm >/dev/null
        or return $status
        printf 'Local vessel %s scuttled; other vessels, outside repositories and other harbors were not removed.\n' "$vessel_name"
        return 0
    end
    for tool in pi tmux nono
        if not command -q "$tool"
            printf 'firstmate: required tool is missing: %s\n' "$tool" >&2
            return 1
        end
    end

    set -l metadata "$anchor/.firstmate/$vessel_name.json"
    if not test -e "$metadata"; and not test -L "$metadata"
        printf 'Sail vessel %s here from another harbor? [y/N] ' "$vessel_name" >&2
        read -l answer; or return 1
        switch "$answer"
            case y Y yes YES
                printf 'Source harbor: ' >&2
                read -l source_harbor; or return 1
                if test -z "$source_harbor"
                    printf 'firstmate: a source harbor is required\n' >&2
                    return 1
                end
                command "$core/bin/fm-anchor.sh" sail $target --from "$source_harbor" >/dev/null
                or return $status
            case '*'
                printf 'Anchor a new vessel named %s here? [y/N] ' "$vessel_name" >&2
                read -l answer; or return 1
                switch "$answer"
                    case y Y yes YES
                        command "$core/bin/fm-anchor.sh" init $target --agent pi >/dev/null
                        or return $status
                    case '*'
                        return 1
                end
        end
    else
        command "$core/bin/fm-anchor.sh" sail $target >/dev/null
        or return $status
    end
    command "$core/bin/fm-anchor.sh" run $target -- \
        nono run \
        --strict-broker-path \
        --profile firstmate \
        --workdir "$core" \
        --read "$core" \
        --allow "$vessel" \
        --allow-file "$anchor/.firstmate/$vessel_name.lock" \
        --read-file "$metadata" -- \
        pi --approve --session-dir "$vessel/pi/primary" --continue --name captain $argv
end
