#!/usr/bin/env fish

if type --query gh
    # Prefer SSH for git operations.
    gh config set git_protocol ssh

    # Reset all aliases.
    gh alias delete --all

    # Cut a new version via GitHub Actions.
    gh alias set --clobber ver \
        'workflow run version.yml --raw-field version="$1"'
else
    echo 'Cannot setup GitHub CLI: gh not found.'
    return 1
end
