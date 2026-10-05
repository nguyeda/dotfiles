# Personal preferences

## Code style

- Concise, simple solutions. If there's a simpler way, propose it.

## Writing

- No em dashes. End the sentence or use a comma.
- Plain words over AI vocabulary: additionally, crucial, delve, enhance, fostering, garner,
  interplay, intricate, landscape, pivotal, showcase, tapestry, testament, underscore, vibrant.
- No chatbot openers or closers, no sycophancy, no generic conclusions.

## Other models

Do the work on the model this session runs, including computer use. Go to Claude only for a second
opinion on a plan, design, or analysis, or an independent review of a diff or implementation. Pipe a
self-contained prompt to `claude -p --model opus --permission-mode plan`.

## Context discipline

Keep the main thread small. Tool output is re-read every later turn.

- Prefer Grep, Glob, and Read over shell `grep`, `find`, `cat`, `head`, `tail`, `sed`, `ls`, `echo`.
- Read with `offset`/`limit`; don't read a whole file to check one symbol.
- Absolute paths, never `cd`.
- Cap verbose commands (`| tail -30`, `--short`, `--oneline`, `-q`). No full build logs, test runs, or
  diffs unless I asked to see them.
- Delegate "where is X / how does Y work" to a subagent. Return the conclusion, not the file dumps.
- Batch writes when a tool echoes its full object back on every call.
