#!/usr/bin/env fish

if type --query gh
    # Install dashboard extension.
    gh extension install --pin v4.24.1 dlvhdr/gh-dash

    # Prefer SSH for git operations.
    gh config set git_protocol ssh

    # Reset all aliases.
    gh alias delete --all

    # Merge pull requests and delete the source branch.
    gh alias set --clobber m 'pr merge --merge --delete-branch'
    gh alias set --clobber ms 'pr merge --squash --delete-branch'
    gh alias set --clobber mrb 'pr merge --rebase --delete-branch'

    # Push the current branch and create a pull request.
    gh alias set --clobber prc '!git push --quiet && gh pr create --fill "$@"'
    gh alias set --clobber prcd '!git push --quiet && gh pr create --fill --draft "$@"'
    gh alias set --clobber prv 'pr view'
    gh alias set --clobber pro 'pr view --web'
    gh alias set --clobber prd 'pr diff'
    gh alias set --clobber prr 'pr ready'
    gh alias set --clobber prw 'pr checks --watch'
    gh alias set --clobber prx 'pr close'

    # Clone repo.
    gh alias set --clobber clone 'repo clone'

    # Cut a new version via GitHub Actions.
    gh alias set --clobber ver \
        'workflow run version.yml --raw-field version="$1"'

    # Manage git remotes and keep upstream (or origin) as gh default repo.
    gh alias set --clobber remote '!f() {
        if [ "$1" = add ] && [ "$#" -eq 3 ]; then
            case "$3" in
                *://*|git@*:*|/*) url="$3" ;;
                */*) url=$(gh repo view "$3" --json sshUrl --jq .sshUrl) || return ;;
                *) url="$3" ;;
            esac
            git remote add "$2" "$url" || return
        else
            git remote "$@" || return
        fi

        if git config --get remote.upstream.url >/dev/null; then
            default=upstream
        elif git config --get remote.origin.url >/dev/null; then
            default=origin
        else
            return
        fi

        gh repo set-default "$default"
    }; f "$@"'
else
    echo 'Cannot setup GitHub CLI: gh not found.'
    return 1
end
