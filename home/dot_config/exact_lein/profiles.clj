; Use XDG for m2 repo location.
; https://wiki.archlinux.org/title/Clojure#m2_repo_location
{:user #=(eval
          (let [cache-home (not-empty (System/getenv "XDG_CACHE_HOME"))
                data-home  (not-empty (System/getenv "XDG_DATA_HOME"))]
            (cond-> {}
              cache-home (assoc :local-repo (str cache-home "/m2"))
              data-home (assoc :repositories
                               {"local" {:url (str "file://" data-home "/m2")
                                         :releases {:checksum :ignore}}}))))}
