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
- Resource ceiling: 2 GiB, 128 tasks. CPU-only local embeddings use the pinned
  `all-MiniLM-L6-v2` model (384 dimensions, approximately 87 MB download).
- Saradomin enables the built-in web UI. A SOPS-provisioned GitHub Copilot token
  supplies LLM summaries, with no paid API fallback. Session-end consolidation is enabled;
  the hourly improvement reviewer stages proposals for manual approval.
  Dream processing, LLM search reranking and cross-project profiles stay off.

These describe the repository configuration, not proof of deployment. The real
bootstrap-token import and native activation/acceptance checks below must happen
separately; the initial encrypted `UNCONFIGURED` marker deliberately blocks
startup.

`AGENTS.md`, current code and verified tests are authoritative. ai-memory holds
historical evidence and handoffs, not permissions or a replacement instructions
hierarchy. Reviewed architecture stays in ordinary repository documentation.

## Configuration ownership

### Everyday quick reference

| Goal | What to ask or run in OpenCode |
|---|---|
| Resume work | "Where did we leave off?" |
| Find previous context | "Search memory for how we configured X." |
| Save an intentional decision | "Remember this decision for this project." |
| Leave useful next-session context | "Wrap up with a handoff." |
| Also close a memory session | `/memory-finish <ai-memory-session-UUID>` |

The server stores searchable project history across machines; it does not
transfer uncommitted code or restore a complete native OpenCode chat. Commit and
push code separately. Repositories without an approved marker are not captured.

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
handoff and durable pages. It also installs the `/memory-finish` prompt command.
No installer runs against the real home.

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

### GitHub Copilot login and usage

The LLM provider is `copilot`, using your GitHub Copilot entitlement rather than
a separately billed model-provider API key. It shares your account's allowance
and rate limits with coding; it is not unlimited. No paid-provider fallback is
configured. To avoid extra charges, also keep paid overages disabled in your
GitHub/Copilot account's billing controls: this Nix configuration cannot enforce
account-level spending settings. Captured content used for summaries and
improvement review leaves Saradomin for Copilot and its model providers;
embeddings and ordinary search stay local. Check your plan's data controls
before enabling this for another repository, particularly work/client code.

Signing into Copilot in OpenCode, VS Code or the Copilot CLI is not an ai-memory
provider login. `ai-memory auth login copilot` on the Mac authenticates that
local data directory. The operator-only importer can encrypt just its GitHub
bootstrap token for Saradomin; it never copies the complete login file.

**Before activating this server configuration**, run the following in your own
private terminal from the repository root, outside a captured agent session:

```sh
# Only if you have not already signed in to ai-memory:
ai-memory auth login copilot

# Preview reads no credentials. Review the public recipients in .sops.yaml.
nix run 'path:.#ai-memory-import-copilot'
nix run 'path:.#ai-memory-import-copilot' -- --confirm
```

The login prints a browser URL and temporary device code; complete it with your
Copilot-enabled GitHub account. Never paste a code or credential into an agent
conversation. The importer uses the native macOS/Linux ai-memory `auth.json`
path (or explicit `--auth-file`), extracts only `copilot.github_access`, rejects
missing/expired tokens and environment-file injection, and passes the token to
SOPS through stdin. It atomically replaces `secrets/ai-memory-copilot.yaml` with
ciphertext only: no plaintext argument, temporary file, stdout or stderr. It
does not change the source login, extract other providers, or import the
short-lived Copilot API token. The initial encrypted value is the intentionally
invalid `UNCONFIGURED` marker; never activate until it has been replaced.

Review the encrypted file and commit it separately before deployment:

```sh
git add secrets/ai-memory-copilot.yaml
git commit -m 'secrets: provision ai-memory Copilot bootstrap token'
```

Saradomin decrypts the bootstrap to `/run/secrets/ai-memory-copilot` and renders
`/run/secrets/rendered/ai-memory-copilot.env`, both owned by `ai-memory`, mode
0400. systemd reads the latter as `EnvironmentFile` to supply
`COPILOT_GITHUB_TOKEN`; only its placeholder and path enter the Nix store.
Missing, blank or unconfigured values fail the pre-start guard. Template changes
schedule a restart during an approved activation, never an agent-initiated live
restart. No separate interactive login on Saradomin is needed for this path.

The server exchanges the GitHub bootstrap token for short-lived Copilot tokens
and maintains its own owner-only `/var/lib/ai-memory/auth.json` cache. Do not
print, commit, copy or SOPS-manage that mutable cache. Expiry or revocation of
the GitHub bootstrap itself requires another local login/import and separately
approved deployment; SOPS does not renew it. Existing cached tokens may remain
valid until expiry, and are not automatically deleted during rotation. The
SOPS bearer used to access the memory server is separate and unchanged.

After approved native build/deployment, an operator can smoke-test the runtime
credential without printing or shell-sourcing it on Saradomin:

```sh
sudo systemd-run --quiet --wait --pipe --collect \
  -p User=ai-memory -p Group=ai-memory \
  -p EnvironmentFile=/run/secrets/rendered/ai-memory-copilot.env \
  /run/current-system/sw/bin/ai-memory --data-dir /var/lib/ai-memory \
  llm-test --provider copilot --model gpt-5.5 --structured --prompt 'Return a short answer'
```

This creates a transient test unit and consumes subscription allowance; it does
not restart the production service. Do not dump its environment or credentials
for diagnostics. The pinned Copilot default (`gpt-5.5`) depends on your
entitlement/model policy: verify access rather than assuming a model available
in OpenCode works through this backend. No paid-provider fallback is configured.

Session-end summaries have a 16,000-token input target and 2,000-token output
limit, with low reasoning effort. Compaction can also queue a summary. Provider
work runs outside hook requests; failures can retry, while deterministic
checkpoints remain available. LLM search reranking is left off so ordinary
recall does not spend subscription allowance.

The improvement scheduler reviews at most one eligible ended session **per
project per hour**, after a ten-minute settling period. It can process existing
eligible sessions too, not just newly captured work. All improvement proposals
require manual approval; they do not automatically rewrite repository files,
skills or `AGENTS.md`. From an opted-in client, inspect this project's queue:

```sh
ai-memory pending-writes list --workspace personal --project nix-config
```

Use `pending-writes show` / `diff` to review a specific proposal before any
explicit `approve` or `reject`. Summaries themselves are generated automatically
and are not approval-gated; treat them as fallible evidence and spot-check them.
Dream processing and cross-session experience synthesis remain off.

### Local embeddings and resource checks

Only the server enables `embedding_provider = "local"`; clients keep it `none`
and query Saradomin over MCP. The service downloads checksum-pinned model files
under `/var/lib/ai-memory/models/` on first start, then performs inference on the
N95's CPU. No GPU or extra inference server is needed. Initial startup requires
download access (or verified offline provisioning); an explicit local provider
fails startup if its model cannot be fetched/loaded rather than silently
pretending vector search is enabled.

The 2 GiB ceiling provides headroom, not preallocated RAM. After separately
approved deployment, measure startup, indexing and query load on Saradomin:

```sh
systemctl show ai-memory -p MemoryCurrent -p MemoryPeak -p MemoryMax
```

Existing pages are backfilled by the server. For an explicit scoped catch-up
from a client, preview then run:

```sh
ai-memory embed --workspace personal --project nix-config --dry-run
ai-memory embed --workspace personal --project nix-config
```

Confirm `memory_query` with `explain=true` reports an active vector stream and
test paraphrases against known pages. The small built-in embedder is English-
focused and truncates long text to 512 tokens; multilingual models can be
evaluated later if Portuguese recall is weak. Its 87 MB download is not a
measurement of peak runtime RAM. Do not run model downloads or real provider
calls from build-time checks.

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

### What "Open" means and how to finish

An **Open** memory session has not received `SessionEnd`; this does not mean its
activity was unsaved. The pinned OpenCode V2 adapter emits a Stop checkpoint and
automatic handoff after a completed root turn. Plugin unload is deliberately not
a session end: OpenCode's shared service can evict an idle location while its
conversations remain resumable. Native session deletion emits an end, but **do
not delete your chats just to close their memory records**.

Use `/memory-finish <ai-memory-session-UUID>` in the conversation you are
finishing. Copy that conversation's memory UUID from the web UI/session metadata
(not an OpenCode `ses_...` identifier or the previous handoff's source ID). The
command asks the agent to verify the observations, finalize only that UUID, and
save a useful handoff. Without an unambiguous user-supplied UUID, it must ask,
not guess from the latest record or close another terminal's session. It is a
prompt workflow, not a new native OpenCode lifecycle event.

The equivalent terminal operation for this repository is:

```sh
ai-memory finalize-session --agent open-code \
  --workspace personal --project nix-config --session-id <UUID> --json
```

Replace `<UUID>`; do not paste angle-bracket placeholders into a shell unchanged.
Verify the reported `finalized` list contains only the intended UUID. A manual
handoff alone does not finalize a session. A session-end queues LLM consolidation
when enabled, but the useful handwritten handoff remains a separate step.

If you resume substantive work in the same native chat after finalizing, capture
can continue under its ended memory ID. Review the new observations and use
the exact command with `--reopen` **only when intentionally re-finalizing that
session**; do not apply it blindly or use `--all` / `--all-owners` for routine
wrap-up. Starting a new OpenCode conversation after finishing avoids this
ambiguity and receives the saved handoff.

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
