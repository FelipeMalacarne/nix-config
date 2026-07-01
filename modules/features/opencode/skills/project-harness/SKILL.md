---
name: project-harness
description: Use when onboarding projects, discovering dev commands, creating or updating AGENTS.md, or setting up docs/ai/* project memory.
---

# Project Harness

Use this skill to make projects easier for AI agents and humans to work in repeatedly.
`docs/ai/` is the canonical LLM Wiki and project memory.

## Inspect

Look for:

- `AGENTS.md`
- `README.md`
- `Makefile`
- `package.json`
- `composer.json`
- `go.mod`
- `docker-compose.yml`
- `Dockerfile`
- `.env.example`
- `docs/ai/`

If `docs/ai/` is missing, propose running `setup-ai-memory`. Do not create harness files unless the user asked for them or approves.

## Canonical Harness Files

- `AGENTS.md`: durable instructions and repo conventions
- `docs/ai/README.md`: how to use project memory
- `docs/ai/index.md`: LLM Wiki entry point and map
- `docs/ai/log.md`: concise durable work log
- `docs/ai/project-context.md`: stack, architecture, services, data stores
- `docs/ai/commands.md`: install, dev, test, lint, build, migrate, Docker commands
- `docs/ai/decisions.md`: important tradeoffs and decisions
- `docs/ai/known-issues.md`: recurring bugs, sharp edges, accepted limitations
- `docs/ai/glossary.md`: domain terms and project-specific vocabulary

## Record Durable Facts

Record facts that will still help future work:

- Canonical commands
- Framework versions and package managers
- Service names and ports
- Test strategy
- Deployment and Docker workflow
- Non-obvious conventions
- Durable architecture and product decisions

## Rules

- Do not create project harness files unless the user asked for harness setup or approves the addition.
- Agents must not edit harness or memory files unless the user asked for updates or approves the proposed changes.
- Do not store secrets, tokens, private URLs, production credentials, or machine-specific absolute paths.
- Separate facts from assumptions; label assumptions clearly.
- Keep harness docs short and maintainable.
- Prefer command examples that actually exist in the project.
