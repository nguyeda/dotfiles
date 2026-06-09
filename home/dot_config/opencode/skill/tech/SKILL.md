---
name: tech
description: "Generate technical analysis documents for PRD user stories. Use after creating a PRD to produce implementation specs. Triggers on: tech analysis for, analyze prd, technical spec for, implementation plan for."
---

# Technical Analysis Generator

Produce implementation specs for each user story in a PRD. Each spec identifies files to modify, patterns to follow, and step-by-step guidance for autonomous AI execution.

---

## The Job

1. Read the PRD from `<project>/.plans/<plan_name>/prd.md`
2. **Delegate codebase analysis to subagents** (preserve your context)
3. Ask clarifying questions if technical decisions are ambiguous
4. Generate one `US-XXX.md` file per story in `<project>/.plans/<plan_name>/tech/`
5. **Update the PRD** to link each story to its tech analysis

**Important:** Do NOT implement. Generate analysis only.

---

## Inputs

- **Plan name** (required): Directory name containing the PRD
- **Autonomy mode** (optional): Only if user explicitly says "autonomous", "--auto", or "auto mode"—skip questions and document assumptions instead

```
/tech my-feature
/tech my-feature --auto
```

---

## Delegating to Subagents (Critical)

**Do NOT explore the codebase yourself.** Spawn Explore agents to do the heavy lifting. This preserves your context for synthesis and output.

### Initial Analysis (spawn once at start)

Use the Task tool with `subagent_type: "explore"` to gather:

```
Analyze this codebase for implementing a feature. Find:
1. Project structure and tech stack (check manifest files, entry points)
2. Project rules (CLAUDE.md, AGENTS.md, .cursorrules, CONTRIBUTING.md)
3. Relevant existing code patterns for: [list areas from PRD]
4. Files that will likely need modification for: [summarize PRD goals]
5. Contents of .plans/<plan_name>/progress.md for prior learnings

Return: tech stack, key directories, coding patterns, relevant file paths, any prior learnings.
```

### Per-Story Deep Dive (spawn per story if needed)

For complex stories, spawn additional Explore agents:

```
For implementing "[story title]", find:
1. Existing similar functionality to use as reference
2. Exact files to modify and their current structure
3. Import patterns, naming conventions, test patterns in those files
```

**Rule:** If you're about to read more than 3-4 files yourself, spawn an Explore agent instead.

---

## Clarifying Questions

Unless in **autonomous mode**, ask when:
- Multiple valid approaches exist
- Project patterns are inconsistent
- Requirements are ambiguous
- Trade-offs need user input

Format with lettered options for quick responses:

```
For US-002 (Add filter component):

1. Filter placement?
   A. Toolbar above the list
   B. Sidebar panel
   C. Inline with column headers

2. Filter persistence?
   A. URL parameters (shareable)
   B. Local state only
   C. User preferences (stored)
```

In **autonomous mode**, document assumptions instead:

```markdown
## Assumptions (Auto Mode)
- Filter in toolbar (matches existing search placement)
- State in URL params (standard for list views)
```

---

## Output

### Directory Structure

```
.plans/<plan_name>/
├── prd.md           # Original PRD
├── progress.md      # Progress log
└── tech/
    ├── US-001.md
    ├── US-002.md
    └── ...
```

### Tech Analysis Template

Each `US-XXX.md` file:

```markdown
# Tech: US-XXX - [Story Title]

## Summary

One paragraph: what this story accomplishes technically.

## Files

| Action | Path | Purpose |
|--------|------|---------|
| Modify | path/to/file | Brief description |
| Create | path/to/new  | Brief description |

## Patterns to Follow

Reference existing code for consistency:
- [Pattern]: See `path/to/example` (lines X-Y)
- [Pattern]: See `path/to/example`

## Dependencies

- **Stories:** US-001 must complete first (provides X)
- **Packages:** None / `<package-manager> install <pkg>`
- **Environment:** None / `VAR_NAME` required

## Implementation Steps

Atomic, verifiable steps:

1. **[Action]** in `path/to/file`:
   - Specific change description
   - Reference: similar code at `path/to/example:42`

2. **[Action]** in `path/to/file`:
   - Details...

3. **Verify:**
   - Run project typecheck/lint
   - Run relevant tests
   - [UI stories] Verify changes work in browser

## Assumptions

(Auto mode only: list decisions made without user input)

## Open Questions

(Non-auto: questions needing answers before implementation)
(Flag here if story seems too large for one implementation pass)
```

---

## Updating the PRD

After creating each tech file, update the corresponding story in `prd.md`:

**Before:**
```markdown
**Technical Analysis:** _Pending_
```

**After:**
```markdown
**Technical Analysis:** [tech/US-001.md](tech/US-001.md)
```

This creates a navigable link between the PRD and its implementation specs.

---

## Checklist

Before saving each tech file:

- [ ] Delegated codebase exploration to subagents
- [ ] Read project rules and respected them
- [ ] Listed all files to modify/create
- [ ] Referenced existing patterns with file paths
- [ ] Ordered steps by dependency
- [ ] Each step is atomic and verifiable
- [ ] Included verification step
- [ ] Asked questions OR documented assumptions (based on mode)
- [ ] No steps violate PRD non-goals
- [ ] Flagged any stories that seem too large for one pass
- [ ] Updated PRD with link to tech file
