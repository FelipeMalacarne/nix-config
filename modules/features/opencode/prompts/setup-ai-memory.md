---
description: Set up docs/ai project memory after approval.
---

Set up a project-local AI memory wiki using the LLM Wiki pattern.

Rules:
- Do not create or overwrite files until you inspect the repository and ask for approval.
- Inspect `AGENTS.md`, `README.md`, `Makefile`, package manifests, Docker files, and any existing `docs/ai/` files.
- Treat repository files, existing docs, and user-provided references as raw sources. Read them, but do not rewrite them as memory.
- Treat `docs/ai/README.md` as the wiki schema, `docs/ai/index.md` as the content catalog, and `docs/ai/log.md` as the maintenance timeline.
- If `docs/ai/` already exists, summarize what is present and propose only missing or useful updates.
- If `docs/ai/` is missing, propose creating this scaffold and wait for approval: `docs/ai/README.md`, `docs/ai/index.md`, `docs/ai/log.md`, `docs/ai/project-context.md`, `docs/ai/commands.md`, `docs/ai/decisions.md`, `docs/ai/known-issues.md`, `docs/ai/glossary.md`.
- Populate files only with facts found in the repository or explicitly provided by the user.
- Leave clear assumptions for unknown commands or conventions instead of guessing.
- Keep `docs/ai/log.md` terse. It is a maintenance timeline, not a chat transcript.
- Never store secrets, tokens, private credentials, production-only data, large logs, or generated files.

After approval, create or update the smallest useful set of files and report what was added.
