---
name: opencode
description: Delegate an implementation task to the opencode CLI in an isolated forked context.
argument-hint: "[provider/model] <task prompt>"
context: fork
disable-model-invocation: true
allowed-tools: Bash(opencode *) Bash(pwd) Bash(git status *)
---

Delegate the requested implementation to opencode from the current project directory.

Arguments: `$ARGUMENTS`

## Argument Handling

- If the first argument looks like `provider/model`, treat it as the opencode model and remove it from the task prompt.
- Otherwise, do not pass `-m`; let opencode use its configured default model.
- The remaining arguments are the task prompt for opencode.
- If no task prompt remains, stop and report that `/opencode` needs a task prompt.

## Execution

1. Run `pwd` and use that directory as the opencode working directory.
2. Run `opencode run --dir <pwd> [-m <provider/model>] <task prompt>`.
3. Use opencode's default output format unless the user explicitly asked for JSON events.
4. Do not implement the task yourself unless opencode fails before doing any useful work.
5. Return opencode's outcome, including any files changed and any verification it ran.

## Notes

- Prefer quoted arguments in the shell command so multi-word prompts and paths survive intact.
- If opencode exits non-zero, include the relevant error output and the command shape that failed.
