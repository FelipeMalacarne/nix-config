---
name: ai-client-troubleshooting
description: Diagnose AI CLI configuration, missing MCP tools, executable/version mismatches, or failures after client upgrades. Use to isolate client, service, configuration, transport and authentication failures across Claude Code and OpenCode.
---

# AI client troubleshooting

Use the repository's more specific diagnostic procedure when one exists. This
workflow does not assume Nix, a particular memory server or a client version.

## Establish the installed client

Record the exact failing command, OS, working directory and error. On POSIX
systems, inspect executable resolution before changing configuration:

```sh
command -v claude
command -v opencode
type -a claude
type -a opencode
```

Run only the affected executable's `--version` and `--help`. A shell alias,
package-manager wrapper and desktop client can select different binaries. Trace
the selected executable to its owner before proposing an upgrade or reinstall.
With declarative configuration, distinguish source, built output and activated
generation; editing source does not update the running client.

## Classify the failure before selecting a repair

| Observation | Check next | What it does not establish |
| --- | --- | --- |
| Config rejected before startup | Exact version's schema and field location | That the server or account is broken |
| Config accepted, MCP server absent | Config discovery, project trust, enablement and precedence | That the MCP transport failed |
| stdio MCP exits immediately | Executable resolution, arguments, working directory and required env names | That reinstalling the AI client will help |
| Remote MCP returns 401/403 | Authentication mechanism, account and authorization scope | Permission to replace credentials or widen access |
| MCP handshake succeeds, tool absent | Advertised tools, client permissions and filtering | That every tool should exist for every account |
| Tools work, capture/history missing | Integration-specific hooks and session lifecycle | That MCP connectivity proves automatic capture |
| Failure starts after upgrade | Binary/config/plugin compatibility and release notes | That an existing database can be safely migrated |

Use installed `--help` and version-matched official documentation to discover
status/config/MCP commands. Do not copy commands between clients or major
versions. For OpenCode V2, distinguish CLI settings from server/project settings
and the terminal process from its background service. For Claude Code, inspect
the effective setting sources and MCP scope rather than assuming a project file
overrides all user or managed settings.

## Inspect the narrowest boundary

1. Identify the configuration owner: package manager, user file, project file,
   environment or organization-managed settings. Inspect relevant keys only;
   avoid printing full merged configuration containing headers or tokens.
2. For stdio MCP, verify the configured executable exists and its arguments
   match that server's documentation. Protocol messages belong on stdout and
   diagnostics on stderr; startup chatter on stdout can break the handshake.
   Do not launch a server manually until its startup side effects are understood.
3. For HTTP MCP, distinguish DNS/TLS/connection failure from HTTP authentication
   and protocol negotiation. Do not paste Authorization headers into commands
   or prompts. Use the client's documented user-facing sign-in flow when needed.
4. Inspect a short, relevant error window. Redact tokens, signed URLs, prompts
   and sensitive paths before sharing logs. Correlate timestamps across client
   and server instead of repeatedly restarting either.

## Isolate without touching native state

For a reproducible version/config problem, create a temporary directory outside
the project and use a fresh HOME plus XDG config/data/cache/state directories.
Check the client's documented config overrides, platform-native directories and
service discovery first: HOME alone may not isolate them. Remove inherited
client config overrides and credentials from the subprocess environment without
printing their values. Disable updates/model fetching when supported.

Start with version, config parsing and path diagnostics. Verify reported state
paths point inside the temporary directory before starting an interactive client.
Do not copy a live database or auth files into the probe. An isolated successful
startup narrows the problem to configuration/state/environment; it does not prove
compatibility with existing chats or a successful migration.

## Close with evidence

Report: selected executable/version, failing boundary, smallest reproducer,
observed result, proposed change and remaining verification. Apply changes through
the configuration owner. Obtain approval before interrupting sessions, replaying
queued events or modifying persistent state. Never use deleting chats/databases,
disabling TLS or broadening permissions as a diagnostic shortcut.
