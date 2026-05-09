---
name: commit
description: Commit files changed in the current session. Build the commit message using local CONTRIBUTING.md rules.
context: fork
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git push:*), Bash(git -C * status:*), Bash(git -C * diff:*), Bash(git -C * add:*), Bash(git -C * commit:*), Bash(git -C * log:*), Bash(git -C * push:*), Bash(gh pr create:*), Bash(gh pr view:*), Bash(gh pr edit:*), Bash(gh pr comment:*), Bash(gh pr ready:*), Bash(gh pr checks:*), Bash(gh pr status:*), Bash(gh api:*)
---

# Commit

Create a git commit for work completed in this session.

## Scope

- Commit only files changed for the current session/task.
- Do not include unrelated changes.
- Respect `.gitignore`; do not force-add ignored files unless explicitly requested.
- Do not commit likely secrets (`.env`, key files, credentials) unless explicitly requested.

## Commit Message Rules

Before writing the message:

1. Read `CONTRIBUTING.md` from the current repository root.
2. Follow its commit message format and wording rules exactly.
3. If `CONTRIBUTING.md` is missing or has no commit guidance, infer style from recent commits (`git log`) and use that.

## Workflow

1. Inspect repo state:
   - `git status`
   - `git diff`
   - `git diff --staged`
   - `git log --oneline -5`
2. If unrelated changes are present, call them out and exclude them.
3. Stage only relevant files for this session.
4. Draft a concise message focused on intent and impact.
5. Commit with `git commit -m "<message>"`.
6. Verify with `git status` and report result.

## Pull Requests

- You may use `git push` and `gh` commands to create a pull request and request review.
- Only perform `git push` and PR creation when explicitly asked by the user.
- If not explicitly asked, stop after commit and report next steps.
- Scope for PR interaction is limited to creating the PR and requesting review.

## Safety

- Never rewrite history unless explicitly requested.
- Never use force push by default.
- If commit hooks fail, fix issues and create a new commit.

## Usage

Invoke with:

```
/commit
```

Optional:

```
/commit <short note about what changed>
```
