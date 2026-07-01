---
name: llm-wiki-memory
description: Use for LLM Wiki project memory, docs/ai files, long-term project context, durable decisions, repeated agent work, and memory linting.
---

# LLM Wiki Memory

Use this skill when a task may benefit from durable project memory stored as markdown.

## Purpose

Compaction helps long conversations continue, but it does not preserve all long-term rationale. Treat `docs/ai/` as a small LLM-maintained wiki for durable project knowledge.

Use the LLM Wiki pattern:

- Raw sources are the repository files, existing docs, and user-provided references. Read them, but do not rewrite them as memory.
- The wiki is `docs/ai/`, a set of maintained markdown files.
- The schema is `docs/ai/README.md` plus project instructions such as `AGENTS.md`.

## Canonical Files

- `docs/ai/README.md`: purpose, conventions, and maintenance rules.
- `docs/ai/index.md`: content-oriented catalog of memory pages with short summaries.
- `docs/ai/log.md`: chronological record of memory ingests, queries, lint passes, and major maintenance updates.
- `docs/ai/project-context.md`: stack, architecture, services, data stores, and important boundaries.
- `docs/ai/commands.md`: install, dev, test, lint, build, migration, and Docker commands.
- `docs/ai/decisions.md`: durable architecture and product decisions with rationale.
- `docs/ai/known-issues.md`: recurring bugs, sharp edges, workaround notes, and operational gotchas.
- `docs/ai/glossary.md`: project-specific terms, domain language, acronyms, and naming conventions.

## Query Workflow

At the start of non-trivial project work:

1. Check `AGENTS.md` and `README.md` when present.
2. If `docs/ai/README.md` exists, read it before reading other memory files.
3. If `docs/ai/index.md` exists, read it to find relevant memory pages.
4. Read only the relevant `docs/ai/*.md` files for the task.
5. If `docs/ai/` is missing, propose running the `setup-ai-memory` command instead of creating files silently.

## Operations

- Ingest: when the user explicitly asks to ingest or update memory, or approves a proposed memory update, extract facts, update relevant pages, update `docs/ai/index.md`, and append a terse entry to `docs/ai/log.md`.
- Query: search the index and relevant pages, answer with file references, and propose filing valuable new synthesis back into the wiki.
- Lint: check for contradictions, stale claims, missing cross-references, orphan pages, duplicated decisions, and useful missing pages.

## Update Workflow

Update memory directly only when the user explicitly asks for memory, wiki, harness, or documentation maintenance, or when the current task already includes updating project memory.

Otherwise, propose the memory update in the final summary or ask before editing `docs/ai/`.

Durable facts worth recording include:

- confirmed commands and services
- architecture boundaries
- important product or engineering decisions
- recurring bugs and fixes
- conventions that affect future edits

Write to the smallest relevant file. Prefer updating an existing section over appending a session diary.

## Safety Rules

- Do not store secrets, tokens, private credentials, production-only data, or personal data.
- Do not store large logs, generated files, or transient command output.
- Do not invent facts to make the wiki look complete.
- Mark assumptions explicitly when they are useful but unconfirmed.
- Ask before creating `docs/ai/` in a project that does not already have it.
- Ask before creating new memory files inside an existing `docs/ai/` directory.
- Keep `docs/ai/log.md` terse. It is a maintenance timeline, not a chat transcript.

## Lint Workflow

When asked to lint project memory:

1. Read `docs/ai/README.md` first.
2. Read `docs/ai/index.md` and `docs/ai/log.md` when present.
3. Check for stale commands, contradictions, duplicated decisions, missing cross-references, orphan pages, and assumptions presented as facts.
4. Keep edits small and factual.
5. Report any uncertainty instead of guessing.
