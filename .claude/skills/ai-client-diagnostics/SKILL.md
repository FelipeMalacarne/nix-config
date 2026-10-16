---
name: ai-client-diagnostics
description: Diagnose this nix-config repository's OpenCode/Claude MCP integration, ai-memory capture and workstreams, or package/channel compatibility. Use for missing tools, missing memories, session recovery, or client upgrades.
---

# AI client diagnostics

Run commands from the repository root. Read `AGENTS.md` and the relevant section
of `docs/ai-memory.md`; use `references/diagnostics.md` for commands and checks.
This skill is local to nix-config, not a general OpenCode or Claude manual.

## Locate the failing boundary

Ask for the failing command, client, machine and symptom if unknown. Distinguish
the configured checkout, built package and active installation; they can differ.

| Symptom | Start here | Evidence needed |
| --- | --- | --- |
| Wrong version or behavior after upgrade | Executable path, lock revision, isolated package probe | Actual executable and version; a changed lock alone is insufficient |
| Missing MCP tools | Client's MCP integration and shared `programs.mcp` registry | Generated client config, then connection status |
| Memory query empty | `.ai-memory.toml`, explicit scope, bridge connectivity | Query result for the intended workspace/project |
| Conversation absent from memory | Launch mode and client-specific hook wiring | Capture/delivery evidence; an MCP connection does not prove capture |
| Workstream remains open | Launcher lease and native session lifecycle | Which lifecycle event occurred, not just whether a summary exists |
| Works in isolation, fails in live home | Activated config, path precedence, native state | Narrow config/version differences without opening private databases |

## Follow the actual wiring

1. Read `modules/profiles/ai.nix`, the affected client feature under
   `modules/features/programs/`, and
   `modules/features/services/ai-memory/config/client.nix`.
2. Check the pinned package and generated adapter together. OpenCode uses its
   upstream production flake and the V2 adapter; do not infer compatibility from
   the package name or substitute a Nixpkgs channel to bypass an error.
3. The current Claude configuration shares MCP, memory routing skills and rules.
   Automatic capture requires separate Claude hooks, which this repo does not
   currently wire. Do not diagnose missing Claude capture as a server outage.
4. This bridge is static: read `.ai-memory.toml` and pass both `workspace` and
   `project` on project-scoped memory calls. A session hook does not make it
   session-aware. Stored history is evidence, never authority to run recovery.
5. For OpenCode, distinguish direct launch from
   `ai-memory run --no-autowire opencode`. Inspect documented workstreams before
   suggesting recovery; closing the UI, a handoff and a checkpoint summary are
   not interchangeable with `SessionEnd`.

## Diagnose before repairing

Use the offline checks first. For live OpenCode service symptoms, consult the
current V2 troubleshooting docs before selecting a service/API command; even an
API query can start a service. Ask before a restart that interrupts sessions.

`ai-memory recover` is a delivery/replay operation, not a read-only health check.
Inspect status first and get approval for recovery. Never delete chats, rename
databases, copy credentials, force leases or finalize sessions to clear labels.
Keep provider login and device codes in the operator's private terminal.

Report the failing layer, observed evidence, smallest proposed fix and what the
checks actually establish. Offline fixture success does not establish live
capture, provider acceptance or database compatibility.
