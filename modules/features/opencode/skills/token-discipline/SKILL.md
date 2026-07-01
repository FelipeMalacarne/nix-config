---
name: token-discipline
description: Use for large repositories, long logs, broad searches, multi-step tasks, or when context size and model cost need control.
---

# Token Discipline

Use this skill to keep context focused and costs controlled.

## Rules

- Search before reading whole files.
- Read the smallest useful file range.
- Prefer summaries over pasting long logs.
- Delegate broad exploration to the built-in `explore` agent when useful.
- Delegate log and document summarization to `docs`.
- Keep durable decisions in a short note instead of re-reading the same context.
- Stop and summarize when the task changes direction.

## Large Output Handling

For long command output:

- Identify the failing command.
- Extract the first relevant error.
- Include the stack trace only when needed.
- Ignore unrelated warnings unless they affect the task.

## Handoff Summary

For long tasks, maintain a concise summary with:

- Goal
- Files touched
- Decisions made
- Commands run
- Current blocker or next step
