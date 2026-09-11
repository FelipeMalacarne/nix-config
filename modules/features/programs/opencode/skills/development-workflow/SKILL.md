---
name: development-workflow
description: Use when no more specific project/domain skill applies for application implementation work, bug fixes, refactors, verification, or handoff summaries.
---

# Development Workflow

Use this skill for routine implementation work across Go, Laravel, React, Next.js, Docker, and other application projects.

## Workflow

1. Inspect project instructions such as `AGENTS.md`, `README.md`, and `docs/ai/` before making changes.
2. Reproduce or understand the current behavior before changing code.
3. Make the smallest correct change.
4. Run the narrowest relevant verification first.
5. Run broader verification when the change crosses boundaries.
6. Summarize changed files, commands run, and any remaining risk.

## Implementation Rules

- Preserve existing project style and structure.
- Prefer established commands from project docs over guessed commands.
- Keep unrelated refactors out of feature and bugfix work.
- Propose project memory updates when you discover durable commands, conventions, or decisions.
- Do not store secrets or transient logs in project memory.
