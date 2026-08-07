# Personal preferences

## Code style

- Concise, simple solutions. If there's a simpler way, propose it.

## Task management

- Shell out to Codex when computer use helps complete or verify work.

## Context discipline

Keep the main thread small — tool output is re-read every later turn.

- Prefer Grep, Glob, and Read over shell `grep`, `find`, `cat`, `head`, `tail`, `sed`, `ls`, `echo`.
- Read with `offset`/`limit`; don't read a whole file to check one symbol.
- Absolute paths, never `cd`.
- Cap verbose commands (`| tail -30`, `--short`, `--oneline`, `-q`). No full build logs, test runs, or
  diffs unless I asked to see them.
- Delegate "where is X / how does Y work" to a subagent. Return the conclusion, not the file dumps.
- Batch writes when a tool echoes its full object back on every call.

## Picking models for workflows and subagents

Higher = better in every column, including cost — **9 = cheapest for me to run**, not most expensive
(GPT is cheap on my OpenAI Pro 5x sub). Columns are independent: check intelligence (how much I can
hand it unsupervised) and taste (UI/UX, code quality, API design, copy) before picking on cost alone.

| model    | cost | intelligence | taste |
| -------- | ---- | ------------ | ----- |
| gpt-5.5  | 9    | 8            | 5     |
| sonnet-5 | 5    | 5            | 7     |
| opus-4.8 | 4    | 7            | 8     |
| fable-5  | 2    | 9            | 9     |

- Defaults, not limits. Escalate to a smarter model without asking when output misses the bar —
  cheaper than shipping mediocre work.
- Use cheap models to explore and gather information first, then move the work up.
- Bulk/mechanical (clear-spec implementation, data analysis, migrations): gpt-5.5.
- User-facing (UI, copy, API design): taste ≥ 7.
- Reviews of plans/implementations: fable-5 or opus-4.8; add gpt-5.5 for an independent perspective.
- Never Haiku.
- gpt-5.5 runs via the Codex CLI (`~/.codex/config.toml` already defaults to it). Use the skills:
  codex-challenge (second opinions), codex-review (diffs), codex-implementation (scoped patches),
  codex-computer-use (GUI/runtime). Anything else: `codex exec -s read-only` with a self-contained
  prompt. `/opencode` is a manual fallback only.
- Claude models run via the Agent/Workflow `model` parameter.
