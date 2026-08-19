---
name: pr-green
description: CI loop for the current pull request. Use when asked to watch CI, fix failing PR checks, or keep working until CI is green and review feedback is addressed.
compatibility: Requires an authenticated GitHub CLI (gh) and a pull request for the current branch.
---

# Iterate on a PR until CI passes

Own the feedback–fix–push–wait loop until a success or stop condition is reached. Invocation authorizes targeted commits and pushes to the current PR branch.

## 1. Identify and guard the PR

```bash
gh auth status
gh pr view --json number,url,headRefName,baseRefName,mergeStateStatus
git status --short --branch
```

Stop if authentication is unavailable or no PR belongs to the current branch. Preserve pre-existing work: never overwrite, stage, or commit unrelated changes. Stop for help if they overlap a required fix.

If the branch has conflicts or GitHub requires it to be updated from the base branch, ask the user to handle or authorize the rebase; never rewrite history automatically.

## 2. Check CI first

```bash
gh pr checks --json name,state,bucket,link,workflow
```

If checks are pending, wait rather than editing against partial results:

```bash
gh pr checks --watch --interval 30
```

In particular, let lint, tests, coverage, and code-analysis checks finish because their bots may post follow-up feedback. If no checks are registered yet, wait 30 seconds and check again.

## 3. Inspect every failure

Read the actual logs; a check name is not a diagnosis. Match runs to the PR head SHA so stale runs are ignored.

```bash
branch=$(git branch --show-current)
gh run list --branch "$branch" --limit 5 --json databaseId,name,status,conclusion,headSha
gh run view <run-id> --log-failed
```

For external checks, follow the `link` returned by `gh pr checks`. Use `gh run view <run-id> --verbose` when failed logs lack enough context.

## 4. Gather feedback after bot checks settle

```bash
gh pr view --json reviews,comments,reviewDecision
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
pr=$(gh pr view --json number --jq .number)
gh api "repos/$repo/pulls/$pr/comments"
gh api "repos/$repo/issues/$pr/comments"
```

For each CI failure or review comment, read the current code and verify that the issue is real, still present, and not already fixed. Act only on valid, unaddressed feedback.

## 5. Fix, validate, commit, and push

Make the smallest root-cause fix. Run the narrowest local check that reproduces the failure plus the repository's required validation for the changed code.

Stage only files changed for this iteration, inspect the staged diff, then commit and push:

```bash
git add -- <files>
git diff --cached
git commit -m "fix: <what was fixed>"
branch=$(git branch --show-current)
git -c credential.https://github.com.helper= \
  -c credential.https://github.com.helper='!gh auth git-credential' \
  push origin "$branch"
```

Return to step 2. Keep looping when checks fail or new valid feedback appears.

## Exit conditions

**Success:** every check is passing or intentionally skipped, and no valid review feedback remains unaddressed.

**Ask for help:**

- The same failure signature survives three fix attempts.
- Feedback requires a product or design decision.
- The failure is flaky, infrastructure-related, or unrelated to this branch.
- The branch needs a rebase, a push is rejected, or required access is missing.

**Stop immediately:** authentication is unavailable, no PR exists for the current branch, or continuing risks unrelated user work.
