---
name: ralph
description: "Execute a PRD using an agent team. Reads a plan from .plans/<name>/, creates a team with specialized teammates, and coordinates parallel implementation of user stories. Triggers on: ralph, execute plan, execute prd, run prd, team execute, start team for."
---

# PRD Team Executor

Coordinate an agent team to implement a PRD's user stories in parallel, using specialized teammates that match the project's agent definitions.

---

## The Job

1. Read the PRD from `.plans/<plan_name>/prd.md`
2. Analyze user stories: extract dependencies, files, and determine which agent type each story needs
3. Create an agent team with `TeamCreate`
4. Create tasks from user stories with proper dependencies using `TaskCreate`
5. Spawn specialized teammates based on project agent definitions
6. Operate as team lead in **delegate mode** — coordinate, don't implement
7. Shut down the team when all stories are complete

**Important:** You are the lead. You do NOT write code. You coordinate teammates.

---

## Inputs

- **Plan name** (required): Directory name under `.plans/` containing the PRD

```
/ralph rbac-permission-checks
```

---

## Step 1: Read and Parse the PRD

Read `.plans/<plan_name>/prd.md` and extract:

- **User stories**: ID, title, description, files, acceptance criteria
- **Dependencies**: From tech analyses in `.plans/<plan_name>/tech/US-XXX.md` (the `Dependencies > Stories` section)
- **Progress**: Check `.plans/<plan_name>/progress.md` for any prior learnings

For each story, also read its tech analysis at `.plans/<plan_name>/tech/US-XXX.md` if it exists. These contain implementation steps, patterns to follow, and file lists.

---

## Step 2: Map Stories to Agent Types

Determine the right agent type for each story based on the **files it touches**. Check the project's `.claude/agents/` directory for available agent definitions.

Use these heuristics (adapt to what agents exist in the project):

| Files / Domain | Agent Type |
|---|---|
| `models.py`, `managers.py`, migrations, `access_control.py` | `model-engineer` |
| `services.py`, `services/`, business logic, authorization, `authorisation.py` | `service-engineer` |
| `api.py`, `schemas.py`, endpoints | `api-engineer` |
| `events.py`, `event/`, domain events | `event-engineer` |
| `test_*.py`, `conftest.py`, `tests/`, `fixtures.py` | `test-engineer` |
| Cross-cutting (multiple domains) | Use the **primary** domain's agent |

If the project has no `.claude/agents/`, fall back to `general-purpose` for all teammates.

---

## Step 3: Group Stories into Work Streams

Group stories by agent type to minimize the number of teammates. Each teammate handles multiple stories of the same type sequentially.

Example grouping:
```
service-engineer: US-001, US-002, US-003, US-004, US-009, US-010, US-011
model-engineer: US-005, US-006
event-engineer: US-007, US-008
test-engineer: US-012, US-013, US-014
```

If a group has many stories (>5), consider splitting into two teammates of the same type (e.g., `service-engineer-core`, `service-engineer-document`).

---

## Step 4: Create the Team

```
TeamCreate with team_name: "<plan_name>"
```

---

## Step 5: Create Tasks with Dependencies

For each user story, create a task using `TaskCreate`:

- **subject**: `US-XXX: <story title>`
- **description**: Include ALL of the following:
  ```
  ## User Story
  <description from PRD>

  ## Technical Analysis
  A detailed technical analysis is available at:
  .plans/<plan_name>/tech/US-XXX.md

  READ THIS FILE BEFORE IMPLEMENTING. It contains:
  - Exact files to modify
  - Patterns to follow (with file paths and line numbers)
  - Step-by-step implementation instructions
  - Dependencies on other stories

  ## Acceptance Criteria
  <criteria from PRD>

  ## Files
  <file list from PRD>
  ```
- **activeForm**: `Implementing US-XXX`

After creating all tasks, set up dependencies using `TaskUpdate` with `addBlockedBy` based on the dependency chain from the tech analyses.

---

## Step 6: Spawn Teammates

For each work stream, spawn a teammate using the `Task` tool:

```
Task tool with:
  subagent_type: "<agent-type>"  (e.g., "service-engineer")
  team_name: "<plan_name>"
  name: "<descriptive-name>"  (e.g., "service-eng-core")
  prompt: |
    You are a teammate on the "<plan_name>" team. Your job is to implement
    assigned user stories from the PRD.

    ## How to Work

    1. Check TaskList to find tasks assigned to you (or claim unassigned, unblocked tasks)
    2. Before starting each task, READ the technical analysis file referenced in the task description
       (at .plans/<plan_name>/tech/US-XXX.md) — it has implementation steps, patterns, and file references
    3. Also read .plans/<plan_name>/progress.md for any learnings from prior work
    4. Implement the story following the tech analysis steps
    5. Run tests after each story: `just test <relevant_path>`
    6. Run lint: `just lint`
    7. Mark the task as completed via TaskUpdate
    8. Record any learnings or patterns discovered in a message to the team lead
    9. Check TaskList for your next task

    ## Plan Directory
    All technical analyses are in: .plans/<plan_name>/tech/
    PRD is at: .plans/<plan_name>/prd.md
    Progress log: .plans/<plan_name>/progress.md

    ## Rules
    - Read the tech analysis BEFORE implementing — it has exact file paths and patterns
    - Follow existing code patterns (check the files referenced in the tech analysis)
    - Run tests after each story
    - If blocked or unsure, message the team lead
    - Do NOT modify files outside your story's scope
```

---

## Step 7: Coordinate

As team lead, your ongoing responsibilities:

1. **Monitor progress**: When teammates go idle or send messages, check TaskList status
2. **Assign tasks**: If tasks are unassigned and a teammate is free, assign via TaskUpdate
3. **Unblock**: If a teammate reports being blocked, help resolve or reassign
4. **Quality gate**: After a work stream completes, consider spawning a `code-reviewer` teammate to review the changes
5. **Update progress**: Record learnings and patterns in `.plans/<plan_name>/progress.md`
6. **Handle failures**: If a teammate reports test failures, investigate and help

### Quality Review (Optional but Recommended)

After all implementation tasks are complete, spawn a code-reviewer teammate:

```
Task tool with:
  subagent_type: "code-reviewer"
  team_name: "<plan_name>"
  name: "reviewer"
  prompt: |
    Review all changes made by the team. Run `just test` and `just lint`.
    Report any issues back to the team lead.
```

---

## Step 8: Wrap Up

When all tasks are completed:

1. Update `.plans/<plan_name>/progress.md` with:
   - Learnings from the implementation
   - Any recurring patterns discovered
   - Suggestions for documentation updates
2. Run final verification: `just test` and `just lint`
3. Send shutdown requests to all teammates
4. Clean up the team with `TeamDelete`
5. Report the summary to the user

---

## Checklist

- [ ] Read PRD and all tech analyses
- [ ] Checked for available agent types in `.claude/agents/`
- [ ] Created team with meaningful name
- [ ] Created tasks with tech analysis references in descriptions
- [ ] Set up task dependencies correctly
- [ ] Spawned appropriate teammates (not too many, not too few)
- [ ] Operating in delegate mode (not implementing directly)
- [ ] Monitoring teammate progress and handling blocks
- [ ] Running quality review after implementation
- [ ] Updated progress.md with learnings
- [ ] Cleaned up team after completion
