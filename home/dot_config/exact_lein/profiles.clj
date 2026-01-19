; Use XDG for m2 repo location.
; https://wiki.archlinux.org/title/Clojure#m2_repo_location
{:user {:local-repo #=(eval (str (System/getenv "XDG_CACHE_HOME") "/m2"))
        :repositories  {"local" {:url #=(eval (str "file://" (System/getenv "XDG_DATA_HOME") "/m2"))
                                 :releases {:checksum :ignore}}}}}
