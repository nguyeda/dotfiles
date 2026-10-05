---
name: handoff
description:
  Compacts the current conversation into a handoff document that a fresh agent can pick up. Use when the user asks
  for a handoff, wants to continue the work in a new session, or wants the session's state written down before
  switching agents.
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it to the OS temporary directory (`${TMPDIR:-/tmp}/handoff-<topic>.md`), not the current workspace, and tell the user the path.

Use this structure as a default and adapt the sections to the work:

```markdown
# Handoff: <topic>

## Goal
## Current state
## Decisions and constraints
## Next steps
## References
## Suggested skills
```

"Suggested skills" lists the skills the next agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
