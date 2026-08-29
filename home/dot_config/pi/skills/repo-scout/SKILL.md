---
name: repo-scout
description: Investigate task-relevant code in another GitHub repository using a disposable clone. Use when a task depends on a repository that is unavailable in the sandbox or current working directory.
compatibility: Requires git and the GitHub CLI; private repositories require gh authentication.
---

# Investigate another repository

Use the clone only as read-only context for the current task. Do not edit, commit, push, install dependencies, or execute code from it.

## 1. Bound the investigation

Identify the repository and the question it must answer. Ask for the repository if it cannot be inferred unambiguously. If one `gh api` or `gh repo view` call answers the question, use that instead of cloning.

## 2. Clone into `/tmp`

Use HTTPS and a unique temporary directory so the current working tree stays clean:

```bash
repo=OWNER/REPO
url=$(gh repo view "$repo" --json url --jq .url)
root=$(mktemp -d /tmp/pi-repo-context.XXXXXX)
gh repo clone "$url" "$root/repo" --no-upstream -- --depth=1
printf '%s\n' "$root"
```

Record the printed path because shell variables do not persist across tool calls. Omit `--depth=1` when the question requires history, tags, or other branches.

## 3. Answer and remove

Search and read only what bears on the question. Report relevant repository-relative paths and commits when applicable, then remove the exact printed temporary path:

```bash
rm -rf -- /tmp/pi-repo-context.PRINTED_SUFFIX
```

The investigation is complete when the task's question is answered and the temporary clone is removed.
