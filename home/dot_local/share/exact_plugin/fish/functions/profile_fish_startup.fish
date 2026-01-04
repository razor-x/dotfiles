function profile_fish_startup \
    --description 'Profiles fish shell startup time'

    set --function tmp (mktemp)
    fish --profile-startup $tmp --interactive --command exit
    sort --numeric-sort --key=1 $tmp
    rm $tmp
end

