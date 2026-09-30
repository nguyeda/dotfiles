## Picking models for workflows and subagents

Use the latest available Sol and Opus models with `xhigh` reasoning effort. Prefer provider family
aliases where supported; otherwise resolve the current concrete model ID from the provider's model
list before dispatch. Set model and effort through the harness or CLI controls.

| Family | Use for |
| ------ | ------- |
| Sol | Default for exploration, implementation, debugging, data work, and computer use. |
| Opus | UI, copy, API design, planning, and reviews of plans or implementations. |

- Sol is inexpensive on my OpenAI Pro 5x subscription. Choose by completed-task quality and time
  before cost. Switch to Opus without asking when Sol's output misses the bar.
- Use the other family for an independent second opinion when it would help.
- Sol runs through the Codex CLI. Pass the resolved model with `-m` and set
  `-c model_reasoning_effort='"xhigh"'`, including when a Codex skill names an older default.
  Use codex-challenge for second opinions, codex-review for diffs, codex-implementation for scoped
  patches, and codex-computer-use for GUI/runtime work. For other read-only tasks, use
  `codex exec -s read-only` with a self-contained prompt. `/opencode` is a manual fallback only.
- Opus runs through the Agent/Workflow model and effort controls, or the Claude CLI when those
  controls do not expose it.
