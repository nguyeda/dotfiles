---
name: codex-challenge
description:
  Ask Codex CLI (gpt-5.5) for an independent second opinion on a plan, design, architecture decision, or analysis —
  challenge assumptions, surface weaknesses, or reassess after new evidence. This is how gpt-5.5 is invoked for
  advisory work. Use when the user asks to challenge a plan or idea, get a second opinion or independent take, ask
  Codex or gpt-5.5 what it thinks, or run another pass after new findings or tests. For reviewing a code diff use
  codex-review; for producing code changes use codex-implementation.
---

# Codex Challenge

Use Codex as an independent sparring partner on plans, designs, and analyses. Claude remains responsible for judging
the critique: verify load-bearing claims against the code before adopting or dismissing them.

Challenges are usually iterative — expect follow-up rounds as decisions evolve or new evidence lands. Always capture
the session id so later rounds resume the same Codex conversation instead of re-explaining context.

## Workflow

1. Create a temporary artifact directory.
2. Write a self-contained prompt: the plan or decision under challenge, hard constraints, options already considered
   and rejected (with the reasons), and the specific questions Claude is least sure about. Codex has repo read access —
   point it at relevant files instead of pasting their contents.
3. Run `codex exec` with a read-only sandbox, in the background.
4. Capture the session id from stderr for follow-up rounds.
5. Read the report, verify the important claims, and respond point by point.

Use this command shape:

```bash
ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/codex-challenge.XXXXXX")"
REPORT="$ARTIFACT_DIR/report.md"
PROMPT="$ARTIFACT_DIR/prompt.md"
STDERR="$ARTIFACT_DIR/stderr.log"

# Write a self-contained prompt to $PROMPT, then run:
codex exec \
  -C "$PWD" \
  -s read-only \
  -o "$REPORT" \
  - < "$PROMPT" > /dev/null 2> "$STDERR"

grep -m1 '^session id:' "$STDERR"
```

Codex runs take minutes. Run the command with the Bash tool's `run_in_background` option and keep doing useful work;
read `$REPORT` when it completes. If a foreground run is genuinely needed, set the timeout to at least 600000 ms —
never leave the default.

## Challenge Prompt

Ask Codex to take an adversarial stance:

```text
You are giving an independent second opinion on the plan below. Challenge it.

- Attack the assumptions. Look for failure modes, missing alternatives, and hidden complexity.
- Apply KISS, DRY, YAGNI: flag over-engineering, premature generality, and single-use abstractions.
- Disagree where warranted; do not be agreeable. If the plan is sound, say so and still name its weakest point.
- Number your points and order them by importance. For each: the claim, why it matters, and what in the repo supports
  it (file references).
- Do not edit files.
```

Then append the plan, constraints, rejected options, and open questions.

## Follow-Up Rounds

When the user asks for another pass, or the plan changed, resume the same session with only the delta — new decisions,
new test results, rebuttals to specific points:

```bash
codex exec -s read-only resume <session-id> -o "$REPORT" - < "$FOLLOWUP" > /dev/null 2> "$STDERR"
```

Global flags go before `resume`. Never use `resume --last`: parallel sessions and worktrees make it ambiguous.

## Reporting Back

Present Codex's points by number, split into: verified and agreed (with what was checked), verified and disputed (with
counter-evidence), and not verified. Give Claude's own recommendation at the end — Codex's opinion is input, not a
verdict. Include the session id so the user can ask for another round later.

If `codex` is not installed or the command fails, report the error and give Claude's own critique directly instead.
