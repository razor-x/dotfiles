#!/usr/bin/env fish

set --local externals home/.chezmoiexternal.yaml
set --local download (mktemp)
or exit
set --local entries (mktemp)
or exit
trap "rm --force $download $entries" EXIT

function update_external \
    --argument-names externals target old_url new_url old_sha256 new_sha256

    set --function contents (string collect --no-trim-newlines <"$externals")
    or return 1
    set --function lines (string split \n -- "$contents")
    set --function line_count (count $lines)
    set --function start 0

    for index in (seq $line_count)
        if test (string trim --right --chars \r -- "$lines[$index]") = "$target:"
            set --function start $index
            break
        end
    end

    if test $start -eq 0
        printf 'external not found: %s\n' "$target" >&2
        return 1
    end

    set --function block_end $line_count
    for index in (seq (math $start + 1) $line_count)
        if string match --quiet --regex '^[^[:space:]#]' -- "$lines[$index]"
            set --function block_end (math $index - 1)
            break
        end
    end

    set --function url_count 0
    set --function sha256_count 0
    for index in (seq $start $block_end)
        set --function url_parts (string split -- "$old_url" "$lines[$index]")
        set --function sha256_parts (string split -- "$old_sha256" "$lines[$index]")
        set --function url_count (math $url_count + (count $url_parts) - 1)
        set --function sha256_count (math $sha256_count + (count $sha256_parts) - 1)
    end

    if test $url_count -ne 1
        printf 'URL not found exactly once for external: %s\n' "$target" >&2
        return 1
    end

    if test $sha256_count -ne 1
        printf 'checksum not found exactly once for external: %s\n' "$target" >&2
        return 1
    end

    for index in (seq $start $block_end)
        set --function lines[$index] (string replace -- "$old_url" "$new_url" "$lines[$index]")
        set --function lines[$index] (string replace -- "$old_sha256" "$new_sha256" "$lines[$index]")
    end

    begin
        for index in (seq $line_count)
            printf %s "$lines[$index]"
            if test $index -lt $line_count
                printf '\n'
            end
        end
    end >"$externals"
end

function latest_release
    gh release view \
        --repo "$argv[1]" \
        --json tagName \
        --jq .tagName 2>/dev/null
end

function head_commit --argument-names repo
    set --function branch (gh api "repos/$repo" --jq .default_branch)
    or return 1
    gh api "repos/$repo/commits/$branch" --jq .sha
end

function resolve_url --argument-names url
    # GitHub source archives pinned to release tags.
    if string match --quiet --regex '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/archive/refs/tags/[^/]+\.tar\.gz$' -- "$url"
        set --function ref (latest_release "$owner/$repo")
        or return 1
        printf 'https://github.com/%s/%s/archive/refs/tags/%s.tar.gz\n' \
            "$owner" "$repo" "$ref"
        return
    end

    # GitHub source archives pinned to commits.
    if string match --quiet --regex '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/archive/[[:xdigit:]]{40}\.tar\.gz$' -- "$url"
        set --function ref (head_commit "$owner/$repo")
        or return 1
        printf 'https://github.com/%s/%s/archive/%s.tar.gz\n' \
            "$owner" "$repo" "$ref"
        return
    end

    # Raw GitHub files pinned to release tags.
    if string match --quiet --regex '^https://raw\.githubusercontent\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/refs/tags/[^/]+/(?<path>.+)$' -- "$url"
        set --function ref (latest_release "$owner/$repo")
        or return 1
        printf 'https://raw.githubusercontent.com/%s/%s/refs/tags/%s/%s\n' \
            "$owner" "$repo" "$ref" "$path"
        return
    end

    # Raw GitHub files pinned to branches.
    if string match --quiet --regex '^https://raw\.githubusercontent\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/refs/heads/[^/]+/(?<path>.+)$' -- "$url"
        set --function ref (head_commit "$owner/$repo")
        or return 1
        printf 'https://raw.githubusercontent.com/%s/%s/%s/%s\n' \
            "$owner" "$repo" "$ref" "$path"
        return
    end

    # Raw GitHub files pinned to commits.
    if string match --quiet --regex '^https://raw\.githubusercontent\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/[[:xdigit:]]{40}/(?<path>.+)$' -- "$url"
        set --function ref (head_commit "$owner/$repo")
        or return 1
        printf 'https://raw.githubusercontent.com/%s/%s/%s/%s\n' \
            "$owner" "$repo" "$ref" "$path"
        return
    end

    # GitHub release assets: preserve the asset name and update the release.
    if string match --quiet --regex '^https://github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/releases/download/[^/]+/(?<asset>.+)$' -- "$url"
        set --function ref (latest_release "$owner/$repo")
        or return 1
        printf 'https://github.com/%s/%s/releases/download/%s/%s\n' \
            "$owner" "$repo" "$ref" "$asset"
        return
    end

    # Non-GitHub/mutable URLs retain their current location.
    printf '%s\n' "$url"
end

yq --unwrapScalar '
  to_entries[]
  | select(.value.checksum.sha256 != null)
  | [.key, .value.url, .value.checksum.sha256]
  | @tsv
' "$externals" >"$entries"
or exit

while read --local --delimiter \t target old_url old_sha256
    set --function new_url (resolve_url "$old_url")
    or exit

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        --output "$download" \
        "$new_url"
    or exit

    set --function checksum (string split ' ' -- (sha256sum "$download"))[1]
    or exit

    update_external "$externals" "$target" "$old_url" "$new_url" "$old_sha256" "$checksum"
    or exit

    if test "$old_url" = "$new_url"
        printf 'refreshed %s\n' "$target"
    else
        printf 'updated %s\n  %s\n  %s\n' \
            "$target" "$old_url" "$new_url"
    end
end <"$entries"
