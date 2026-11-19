---
name: ai-client-diagnostics
description: Diagnose this nix-config repository's OpenCode/Claude MCP integration or package/channel compatibility. Use for missing tools, wrong client versions, or client upgrades.
---

# AI client diagnostics

Run commands from the repository root. Read `AGENTS.md`; use
`references/diagnostics.md` for commands and checks.
This skill is local to nix-config, not a general OpenCode or Claude manual.

## Locate the failing boundary

Ask for the failing command, client, machine and symptom if unknown. Distinguish
the configured checkout, built package and active installation; they can differ.

| Symptom | Start here | Evidence needed |
| --- | --- | --- |
| Wrong version or behavior after upgrade | Executable path, lock revision, isolated package probe | Actual executable and version; a changed lock alone is insufficient |
| Missing MCP tools | Client's MCP integration and shared `programs.mcp` registry | Generated client config, then connection status |
| Works in isolation, fails in live home | Activated config, path precedence, native state | Narrow config/version differences without opening private databases |

## Follow the actual wiring

1. Read `modules/profiles/ai.nix` and the affected client feature under
   `modules/features/ai/`.
2. Check the pinned package and generated config together. OpenCode uses its
   upstream production flake; do not infer compatibility from the package name
   or substitute a Nixpkgs channel to bypass an error.

## Diagnose before repairing

Use the offline checks first. For live OpenCode service symptoms, consult the
current V2 troubleshooting docs before selecting a service/API command; even an
API query can start a service. Ask before a restart that interrupts sessions.

Never delete chats, rename databases, copy credentials or force leases to clear
a symptom.

Report the failing layer, observed evidence, smallest proposed fix and what the
checks actually establish. Offline fixture success does not establish provider
acceptance or database compatibility.
