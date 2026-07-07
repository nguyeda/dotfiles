# Personal preferences

## Code style

- Always strive for concise, simple solutions
- If a problem can be solved in a simpler way, propose it

## Task management

- If computer use is helpful for completing or verifying work, shell out to Codex for it

## Picking the right models for workflows and subagents

Rankings, higher = better. Cost reflects what I actually pay, not list price: GPT inference is cheap for me on the
OpenAI Pro 5x subscription, noticeably lower than Opus on a comparable Pro 5x sub. Intelligence is how hard a problem
you can hand the model unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model    | cost | intelligence | taste |
| -------- | ---- | ------------ | ----- |
| gpt-5.5  | 9    | 8            | 5     |
| sonnet-5 | 5    | 5            | 7     |
| opus-4.8 | 4    | 7            | 8     |
| fable-5  | 2    | 9            | 9     |

How to apply:

- These are defaults, not limits. You have standing permission to override them: if a cheaper model's output doesn't
  meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag.
  Escalating costs less than shipping mediocre work.
- Don't let cost prevent you from using the right model for the job. Instead take advantage of cheaper options to get
  more information and try things, before moving the work to a more expensive option.
- Bulk/mechanical work (clear-spec implementation, data analysis, migrations): gpt-5.5 — it's cheap.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 as an extra independent perspective.
- Never use Haiku.
- Mechanics: gpt-5.5 runs through the Codex CLI — `codex exec` (my ~/.codex/config.toml defaults to gpt-5.5). Use the
  codex skills: codex-challenge (second opinions on plans/designs), codex-review (diff review), codex-implementation
  (scoped patches), codex-computer-use (GUI/runtime verification). For work they don't cover (investigation, data
  analysis), run `codex exec -s read-only` directly with a self-contained prompt. Codex replaces opencode as the
  gpt-5.5 channel; `/opencode` remains as a manual, user-invoked fallback only.
- Claude models (sonnet-5, opus-4.8, fable-5) run via the Agent/Workflow model parameter.
