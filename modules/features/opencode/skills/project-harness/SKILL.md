---
name: project-harness
description: Use when onboarding a project, discovering dev commands, creating AGENTS.md, or improving docs/ai project harness files.
---

# Project Harness

Use this skill to make projects easier for AI agents and humans to work in repeatedly.

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

## Capture Durable Context

Useful project harness files:

- `AGENTS.md`: durable instructions and repo conventions
- `docs/ai/project-context.md`: stack, architecture, services, data stores
- `docs/ai/commands.md`: install, dev, test, lint, build, migrate, Docker commands
- `docs/ai/decisions.md`: important tradeoffs and decisions

## Rules

- Do not create project harness files unless the user asked for harness setup or approves the addition.
- Do not store secrets, tokens, private URLs, or machine-specific absolute paths.
- Separate facts from assumptions.
- Keep harness docs short and maintainable.
- Prefer command examples that actually exist in the project.

## When Updating Harness Docs

Record only durable facts discovered during work:

- Canonical commands
- Framework versions and package managers
- Service names and ports
- Test strategy
- Deployment or Docker workflow
- Non-obvious conventions
