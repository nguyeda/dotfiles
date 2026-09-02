# Personal preferences

## Code style

- Concise, simple solutions. If there's a simpler way, propose it.
- Edit surgically. Where it won't change the end result, patch the lines that need changing rather
  than rewriting the whole file — a rewrite costs output tokens and time for the same diff.
- A pre-existing bug, performance smell, or unmentioned behaviour found while working is a follow-up
  to report in the summary, not a fix to land in this change — unless the requested behaviour can't
  work without it.
- Commit tests only where the task asks for them or the repo already keeps tests for this kind of
  change, sized like the neighbouring test files. Scratch scripts and one-off checks stay scratch;
  don't promote them into permanent test files.

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

Rows are families — use the current member of the family, not a pinned version. Higher = better in
every column. Columns are independent; check intelligence (how much I can hand it unsupervised) and
taste (UI/UX, code quality, API design, copy) before picking on cost alone.

- **cost** — 9 = cheapest for me to run, not most expensive (GPT is near-flat on my OpenAI Pro 5x sub).
- **efficiency** — tokens burned per *completed task*, 9 = leanest. Separate from cost: it drives
  wall-clock, context exhaustion, and how many turns a job takes even when the sub is flat.
- **context** — usable window in practice, not the headline number.

| family    | cost | efficiency | intelligence | taste | context |
| --------- | ---- | ---------- | ------------ | ----- | ------- |
| gpt-terra | 9    | 9          | 7            | 5     | 6       |
| gpt-sol   | 8    | 8          | 9            | 5     | 6       |
| sonnet    | 5    | 6          | 5            | 7     | 9       |
| opus      | 4    | 5          | 8            | 8     | 9       |
| fable     | 2    | 2          | 9            | 9     | 9       |

- Defaults, not limits. Escalate to a smarter model without asking when output misses the bar —
  cheaper than shipping mediocre work.
- Use cheap models to explore and gather information first, then move the work up.
- Bulk/mechanical (clear-spec implementation, data analysis, migrations): gpt-terra, escalating to
  gpt-sol for long-horizon or multi-file work.
- User-facing (UI, copy, API design): taste ≥ 7.
- Reviews of plans/implementations: fable or opus; add gpt-sol for an independent perspective.
- Never Haiku.
- Context caveats: Claude 1M needs the `[1m]` variant. GPT is ~1M in the API but Codex caps the
  window at 272K, and GPT pricing steps up past 272K input — treat 272K as the real ceiling there.
- Fable earns its intelligence and taste scores but is the least token-efficient family: it rewrites
  whole files for small edits, batches tool calls less, and at `xhigh`/`max` can draft a deliverable
  in reasoning and then write it again. Budget for that, or pass it the anti-over-editing rules from
  Code style. Cheap cache reads offset some of it on long sessions that re-read one prefix.
- gpt-sol/terra run via the Codex CLI (`~/.codex/config.toml` defaults to `gpt-5.6-sol`). Use the skills:
  codex-challenge (second opinions), codex-review (diffs), codex-implementation (scoped patches),
  codex-computer-use (GUI/runtime). Anything else: `codex exec -s read-only` with a self-contained
  prompt. `/opencode` is a manual fallback only.
- Claude models run via the Agent/Workflow `model` parameter.
