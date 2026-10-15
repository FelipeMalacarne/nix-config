---
name: project-harness
description: Use when onboarding projects, discovering verified dev commands, or creating and maintaining AGENTS.md and project documentation.
---

# Project Harness

Use this skill to make projects easier for AI agents and humans to work in repeatedly.
Repository instructions and documentation are authoritative. ai-memory provides
optional searchable history and handoffs, not a second instruction hierarchy.

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
- Existing architecture/decision and operational documentation
- `.ai-memory.toml`, if the repository has explicitly opted into capture

Do not scaffold a parallel memory wiki. Preserve existing project documentation,
including any existing `docs/ai/` files. Do not create harness files or opt a
repository into capture unless the user asked for it or approves.

## Canonical Harness Files

- `AGENTS.md`: durable instructions and repo conventions
- `README.md`: project overview and verified commands
- Existing docs/ADRs: architecture, decisions, operational procedures
- `.ai-memory.toml`: approved capture scope, exclusions, and bounded briefing

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
