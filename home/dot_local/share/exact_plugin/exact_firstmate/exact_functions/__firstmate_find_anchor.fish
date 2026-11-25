function __firstmate_find_anchor --argument-names directory --description 'Find the nearest directory containing .firstmate'
    set --local anchor (path resolve -- "$directory")
    test -d "$anchor"; or return 1
    while not test -d "$anchor/.firstmate"
        test "$anchor" != /; or return 1
        set anchor (path dirname -- "$anchor")
    end
    printf '%s\n' "$anchor"
end
