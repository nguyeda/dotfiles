---
name: codex
description: Delegate tasks to OpenAI Codex CLI agent. Use /codex to run code generation, refactoring, or review tasks.
allowed-tools: Bash(codex:*)
---

# OpenAI Codex CLI

Delegate tasks to OpenAI's Codex agent.

## Non-Interactive Execution

```bash
# Basic execution
codex exec "your prompt here"

# With specific model
codex exec -m gpt-5-codex "your prompt"

# Full auto mode (workspace write, no approval)
codex exec --full-auto "your prompt"

# Output to file
codex exec -o result.md "your prompt"

# JSON output for parsing
codex exec --json "your prompt"
```

## Sandbox Policies

- `read-only` - No file writes (safest)
- `workspace-write` - Write only in current workspace
- `danger-full-access` - Full system access (use with caution)

```bash
codex exec -s workspace-write "refactor the auth module"
```

## Approval Modes

- `untrusted` - Ask before any tool use
- `on-failure` - Ask only on errors
- `on-request` - Ask when agent requests
- `never` - Full automation

```bash
codex exec -a never --full-auto "add tests for user service"
```

## Code Review

```bash
codex review
```

## Resume Session

```bash
codex exec resume [SESSION_ID]
```

## Usage

Invoke with `/codex <prompt>`:

```
/codex add unit tests for the user service
```
