---
name: codex-review
description:
  Ask Codex CLI (gpt-5.5) for an independent code review of uncommitted changes, a base branch diff, a commit, or a
  specific implementation. This is how gpt-5.5 is invoked for review work. Use when the user asks Claude to have Codex
  or gpt-5.5 review work, when the model-selection rubric calls for a gpt-5.5 review perspective, or when Codex should
  audit a diff, find bugs or regressions, or compare Claude's implementation against requirements. For a review by
  Claude itself, use the normal review process instead.
---

# Codex Review

Use Codex as an independent reviewer when the user wants a second-pass review or when a change is broad enough that
another agent's perspective is useful.

This is the local pre-PR / pre-merge gate. Open PRs already get automated cloud reviews (Cubic, Codex cloud) — do not
re-run what a PR already received unless the user asks for a fresh pass; the value here is catching issues before the
PR exists or before a merge.

Prefer Claude's normal review process for small local checks. Do not delegate review just to avoid reading the code
yourself. Treat Codex's output as evidence, not authority.

## Workflow

1. Identify the review target: uncommitted changes, base branch, commit SHA, PR checkout, or specific files.
2. Create a temporary artifact directory for the Codex report.
3. Run `codex review` with a focused review prompt, in the background.
4. Read Codex's report and verify important claims against the code before presenting them.

Use one of these command shapes:

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
REPORT="$ARTIFACT_DIR/report.md"
PROMPT="$ARTIFACT_DIR/prompt.md"
STDERR="$ARTIFACT_DIR/stderr.log"

# Review staged, unstaged, and untracked changes.
codex -C "$PWD" review --uncommitted - < "$PROMPT" > "$REPORT" 2> "$STDERR"

# Review current branch against a base branch.
codex -C "$PWD" review --base main - < "$PROMPT" > "$REPORT" 2> "$STDERR"

# Review a single commit.
codex -C "$PWD" review --commit <sha> - < "$PROMPT" > "$REPORT" 2> "$STDERR"

grep -m1 '^session id:' "$STDERR"
```

Codex runs take minutes. Run the command with the Bash tool's `run_in_background` option and keep doing useful work;
read `$REPORT` when it completes. If a foreground run is genuinely needed, set the timeout to at least 600000 ms —
never leave the default.

## Review Prompt

Ask Codex to use a code-review stance and produce findings the user can triage by number:

```text
Review these changes for bugs, regressions, missing tests, security issues, and requirement mismatches.

Pay particular attention to:
- concurrency: races, event ordering, duplicate delivery, concurrent writes
- regressions, especially unintended changes from merging the base branch
- test coverage: gaps should be explicit exclusions, not silent; flag duplicated assertions and multi-concern tests
- type errors the project's type checker would catch
- security: injection, authorization gaps, credential handling

Prioritize findings over summary. Number every finding, order by severity (P1 correctness/data loss, P2 should fix,
P3 nice to have), and for each include:
- severity
- file and line reference
- concrete failure mode
- suggested fix direction

Do not edit files. If there are no substantive findings, say so and name any residual test gaps.
```

Add task-specific context when useful: requirements, risky areas, expected behavior, relevant tests, or files Claude is
unsure about.

If the project ships its own review skill, that skill stays authoritative and mandatory where its workflow says so —
Codex adds an independent perspective on top, it never substitutes for the project review. When the project's plugin is
also installed in Codex, instruct Codex to apply the project review skill by name; otherwise fold the project rubric
into the prompt in place of the generic list above.

## Reporting Back

Before relaying a Codex finding, inspect the named code or diff enough to decide whether the finding is real. In the
user-facing response, keep Codex's numbering and severity ordering so the user can answer per item ("3 fix, ignore the
rest"), and separate confirmed issues from Codex suggestions you did not verify.

For follow-up rounds after fixes land, resume the same Codex session with the delta instead of re-running a full
review: `codex exec resume <session-id> - < "$FOLLOWUP"` (global flags before `resume`; never `resume --last` —
parallel sessions and worktrees make it ambiguous).

If Codex finds nothing, say that clearly and mention what review target it inspected.

If `codex` is not installed or the command fails, report the error and offer to review the changes directly instead.
