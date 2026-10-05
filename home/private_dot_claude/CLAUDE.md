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

## Writing

- No em dashes. End the sentence or use a comma.
- Plain words over AI vocabulary: additionally, crucial, delve, enhance, fostering, garner,
  interplay, intricate, landscape, pivotal, showcase, tapestry, testament, underscore, vibrant.
- No chatbot openers or closers, no sycophancy, no generic conclusions.

## Other models

Do the work on the model this session runs. Subagents and workflows inherit it; don't set a model to
hand off exploration, implementation, or debugging. Go to Codex only for:

- A second opinion on a plan, design, or analysis: codex-challenge.
- An independent review of a diff or implementation: codex-review.
- Computer use (browser, simulators, screenshots, app launching), where Codex is stronger:
  codex-computer-use.

Codex runs on the model and effort in its own config, so don't pass `-m`.

## Context discipline

Keep the main thread small — tool output is re-read every later turn.

- Prefer Grep, Glob, and Read over shell `grep`, `find`, `cat`, `head`, `tail`, `sed`, `ls`, `echo`.
- Read with `offset`/`limit`; don't read a whole file to check one symbol.
- Absolute paths, never `cd`.
- Cap verbose commands (`| tail -30`, `--short`, `--oneline`, `-q`). No full build logs, test runs, or
  diffs unless I asked to see them.
- Delegate "where is X / how does Y work" to a subagent. Return the conclusion, not the file dumps.
- Batch writes when a tool echoes its full object back on every call.
