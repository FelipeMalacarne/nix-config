# Shared AI workflow

## Architecture

One pinned [ai-memory](https://github.com/akitaonrails/ai-memory) server on
**saradomin**, native systemd, with clients on **macbook** and **zaros**.
No Kubernetes deployment, local replica server, cloud memory provider or
automatic instruction rewriting. The old `/setup-ai-memory` command and
`llm-wiki-memory` skill have been retired; existing project docs are not deleted.

- Server feature: `self.modules.nixos.ai-memory-server`.
- Workstation composition: `self.modules.nixos.ai` / `self.modules.darwin.ai`,
  explicitly selected by zaros/macbook. It combines the Home Manager `ai`
  coding profile (OpenCode, Claude Code, Codex, GitHub Copilot CLI) with the
  SOPS-backed system memory-client role, which forwards its Home Manager module.
  `development` no longer selects AI tools. Hermes remains opt-in on zaros;
  ai-usagebar is deferred.
- Memory client roles: `self.modules.nixos.ai-memory-client` /
  `self.modules.darwin.ai-memory-client` own SOPS provisioning and forward
  `self.modules.homeManager.ai-memory-client`. Hosts only supply the endpoint.
- One cohesive dendritic feature lives at `modules/features/services/ai-memory/`:
  `ai-memory.nix` is its only discovered entrypoint and explicitly imports the
  server/client implementations under `config/`. The package, checks, workflow
  policy and test fixtures live with the same feature; there is no separate
  `programs/ai-memory` feature. The server remains explicitly selected only by
  saradomin; it does not receive the workstation profile.
- Private endpoint: `https://saradomin.osiris-fish.ts.net:8443`.
- Backend: `127.0.0.1:49374`; no new firewall port or public ingress.
- A foreground Tailscale Serve unit owns only its dedicated HTTPS listener. It
  refuses an occupied port, never resets Serve, and never enables Funnel.
- Data: `/var/lib/ai-memory` (wiki, raw data, SQLite, credentials and history).
- Resource ceiling: 1 GiB, 128 tasks; embeddings explicitly disabled initially.
- Saradomin enables the built-in web UI. LLM provider is unset; dream, cross-project profile and the
  auto-improvement scheduler are disabled. Proposals require approval.

`AGENTS.md`, current code and verified tests are authoritative. ai-memory holds
historical evidence and handoffs, not permissions or a replacement instructions
hierarchy. Reviewed architecture stays in ordinary repository documentation.

## Configuration ownership

### Private web UI

After approved deployment, open
**https://saradomin.osiris-fish.ts.net:8443/web** from a device connected to your
tailnet. The built-in interface is a read-only wiki browser, not a full admin
console. It shares the existing HTTPS endpoint; no public ingress is added.

For this initial bearer-only/single-user setup, the browser displays an HTTP
Basic login prompt: use any username (for example `felipe`) and the server bearer
token as the password. Retrieve it through your approved credential mechanism,
never an agent prompt or URL. The browser caches Basic credentials; use a
private browser window on shared devices. A future multi-user setup changes
this authentication flow and must be configured separately.

### Managed agent integration

Home Manager installs the pinned CLI, generates the upstream OpenCode V2 adapter
**inside the Nix build sandbox**, and installs three upstream skills: retrieval,
handoff and durable pages. No installer runs against the real home.

MCP uses the local `ai-memory mcp-bridge --no-session-id`, reading credentials at
runtime and connecting to the shared server. This is a **static** client: pass
both workspace and project on every project-scoped call, even with lifecycle
hooks enabled. The installed workflow instructions explain this requirement.

Do not run `ai-memory setup`, `upgrade`, or live `install-*` commands over managed
configuration. `ai-memory run` must use `--no-autowire`; the session environment
also sets `AI_MEMORY_RUN_AUTOWIRE=false`. Update through flake inputs and rebuild.

Client data and config use the CLI/adapter's native directories:

| Platform | Directory |
|---|---|
| macOS | `~/Library/Application Support/ai-memory` |
| Linux | `$XDG_DATA_HOME/ai-memory` (normally `~/.local/share/ai-memory`) |

Home Manager owns `config.toml`, `capture-mode`, and the `auth-token` symlink
there. SOPS owns the credential contents; the client owns its spools.
Preserve existing data; a conflicting existing config/token requires manual
review before activation. Do not use environment overrides that route the CLI
and plugin to different data directories or servers.

## First deployment checklist — approval required

Configuration/build preparation is not deployment approval. On the appropriate
native machines, finish formatting, evaluation, affected closure builds and the
`ai-memory-client` check first. Do not cross-activate NixOS from macOS.

Before activating the server:

1. Confirm Tailscale is enrolled and the configured MagicDNS name is correct.
2. Confirm tailnet HTTPS certificates are enabled. This is an administrator action;
   the configuration does not change tailnet policy, ACLs, grants or enrollment.
3. Review access to `saradomin:8443`: tailnet reachability alone is not a
   per-device ACL. Restrict to the intended operator/devices before real capture.
4. Inspect `tailscale serve status --json` and ensure port 8443 is unused and is
   not exposed through Funnel. Resolve conflicts deliberately; never reset Serve.
5. Approve the server activation separately. Workstation activation is also
   separate; zaros retains its controlled next-boot/TTY-recovery requirement.

### SOPS-managed credential — no manual password transfer

The same 256-bit bearer is encrypted in `secrets/ai-memory.yaml`, using the
repository's **existing** SOPS age recipient. The memory feature's selected
server/client role declares `sops.secrets.ai-memory-token`, decrypted to
`/run/secrets/ai-memory-token`:

- saradomin: owner/group `ai-memory`, mode **0400**; the service reads this path
  through `my.ai-memory-server.tokenFile`. It generates no separate token.
- macbook and zaros: owner is the configured human user, mode **0400**;
  `my.ai-memory.tokenFile` forwards the runtime path to Home Manager, which
  creates `<client-data-dir>/auth-token` as an out-of-store symlink. Both the
  OpenCode plugin and MCP bridge follow it. The client data directory is 0700.

Only ciphertext and runtime path references enter the Nix store, never the
decrypted token. The service checks that its token file is readable and contains
non-whitespace before starting, so missing credentials cannot silently disable
authentication. SOPS schedules an ai-memory restart when that secret changes
during an approved server activation; do not rotate while queues have old tokens.

The existing SOPS age-key bootstrap at `/var/lib/sops-age/keys.txt` is unchanged.
Each machine must already have the appropriate identity there. Decryption was
verified on macbook and saradomin without displaying the token; zaros still
needs its normal native validation. No keys or trust policy were added.

Apply the **latest SOPS-enabled revision on saradomin first**, then apply it on
the MacBook/zaros when separately approved. SOPS provisions the matching token
on each machine automatically; no copying, `ai-memory init`, or interactive
pairing is necessary. If an older manual `auth-token` file already exists,
review Home Manager's conflict rather than overwriting it automatically.

This remains one powerful single-user/operator bearer, with no separate device
revocation. Web login still uses it as the password; never paste it into an agent
prompt or URL. The administrator's **sudo password** for system activation is
unrelated to this token and still requires your own interactive authentication.

After separately approved workstation activation, open a new OpenCode session,
verify its MCP connection, run
`ai-memory status`, and test a harmless opted-in project on both machines. Until
pairing and HTTPS connectivity are verified, capture/recall are not operational.

## Project opt-in and routine work

Capture uses **allowlist mode**: an unmarked repository emits no lifecycle
captures. Do not put a marker at `$HOME` or a broad work directory because that
can opt descendant repositories in. A marker is not an authorization boundary
against malicious repositories; review it when trusting a checkout.

This repository's `.ai-memory.toml` opts only this tree in under workspace
`personal`, project `nix-config`, and pins identity `felipemalacarne/nix-config`
so SSH aliases such as `github-zaros` do not split the repository's history.
It disables profile contribution/consumption and
caps its startup brief at 4000 characters. Markers should be committed for
approved projects so clones and worktrees use the same explicit scope.

File exclusions are **best-effort lexical filters**, not complete DLP. They do
not prevent credential text pasted into prompts, indirect shell reads, symlink
aliases or every unknown tool. Never decrypt/read secrets in an opted-in agent
session. Do not opt sensitive work repositories in without their owner's consent.

Typical workflow:

1. Start OpenCode normally; ask for prior context when useful.
2. Search narrowly, verify remembered claims against current files, then work.
3. Ask to save durable knowledge only when intentional; avoid duplicate notes.
4. Ask to **wrap up with a handoff** before changing machines. Closing a TUI or
   evicting an idle OpenCode location does not necessarily end the native session.
5. Commit/push code separately. Memory does not transfer uncommitted changes,
   running processes or the full native OpenCode session.

## Saradomin unavailable

**Continue coding, with degraded recall.** Repository docs, local conversations
and working files remain available. No offline recall cache is provided and no
second server starts automatically: there is one writer for the shared history.

The pinned OpenCode adapter queues retryable failed deliveries under the client
data directory's `hook-spool/`. It retries on later activity/flushes when the
server returns, preserving ingest keys. The integration check exercises an
outage, bounded cleanup, private spool permissions, capture exclusions,
unmarked-repository silence and successful replay using an isolated mocked host.
The server check also starts an isolated loopback-only fixture with a dummy
credential to validate the rendered settings, health, authentication and MCP
discovery. It never touches the deployed service or real data.

This is **best-effort buffering, not guaranteed lossless capture**:

- A crash can lose the in-memory queue before it reaches disk; full/read-only
  disks or shutdown interruption can also lose events.
- Spool files can contain a bearer and private content. Do not print, commit,
  casually upload, sync publicly or delete them during diagnosis.
- Permanent HTTP rejections, including 401/403, are not queued like network
  outages. The TypeScript drain removes permanently rejected entries. Restore
  connectivity/authentication before replay, especially after token rotation.
- Managed-run journal/transcript recovery applies only to runs launched through
  `ai-memory run --no-autowire ...`; ordinary OpenCode sessions use hook spooling.

When the server returns, on **each** affected client:

```sh
ai-memory status
ai-memory recover
ai-memory status
```

Check pending spool counts and verify a harmless recent fact/handoff from the
other machine. `recover` drains capture and processes managed-run recovery
journals where applicable; it cannot recover arbitrary lost native events.
Do not run a loop of failed memory calls while coding offline.

For an extended outage, keep a short local handoff in the conversation or
ordinary user-approved notes. If the server is permanently lost, restore its
backup to one replacement, preserve its credentials/identity, verify it, then
replay client queues. Do not point old queues at a fresh unauthenticated server
or run two servers against the same data directory.

## Backup and operational acceptance

The wiki's local Git history is **not a backup**. No backup schedule, restore
claim, remote deployment or real-service restart is introduced by this change.
Before relying on the service, approve an encrypted off-host backup target,
retention and a consistent snapshot procedure covering the **whole data
directory**, including auth material, not just derived SQLite or wiki files.
Test a restore separately without exposing it or starting a second writer.
Rebuilding Nix restores software/configuration, not lost runtime memory.

Native server and two-machine HTTPS/auth/capture/recall checks, occupied-port
behavior, reboot persistence and backup/restore verification remain deployment
acceptance gates. Build-time mocks do not verify live tailnet state.
