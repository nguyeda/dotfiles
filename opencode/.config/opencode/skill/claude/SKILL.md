---
name: claude
description: Delegate tasks to Anthropic Claude Code CLI. Use /claude to run prompts via the CLI.
allowed-tools: Bash(claude:*)
---

# Claude Code CLI

Delegate tasks to Anthropic Claude Code via the `claude` CLI.

## Non-Interactive Execution

```bash
# Basic execution (print mode)
claude -p "your prompt here"

# Choose a model (defaults to Opus 4.5)
claude -p --model opus "your prompt"

# Use a specific model name
claude -p --model claude-opus-4-5-20250929 "your prompt"

# Continue the most recent conversation
claude -c -p "continue this task"

# Resume a session by name or ID
claude -r "auth-refactor" -p "finish this PR"
```

## Model Selection

Use `--model` to select a model. Default to Opus 4.5 (`--model opus`) unless the user specifies otherwise.

## Usage

Invoke with `/claude <prompt>`:

```
/claude summarize this change set
```
