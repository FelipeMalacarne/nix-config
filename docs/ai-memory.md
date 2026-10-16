# Shared AI workflow

## Architecture

One pinned [ai-memory](https://github.com/akitaonrails/ai-memory) server on
**saradomin**, native systemd, with clients on **macbook** and **zaros**.
No Kubernetes deployment, local replica server, cloud memory provider or
automatic instruction rewriting. The old `/setup-ai-memory` command and
`llm-wiki-memory` skill have been retired; existing project docs are not deleted.

- Server feature: `self.modules.nixos.ai-memory-server`.
- The server imports the [official NixOS module](https://github.com/akitaonrails/ai-memory#nixos)
  (`inputs.ai-memory.nixosModules.default`); upstream owns its system user,
  service, sandbox and TOML generation. Our extra server policy covers private
  Tailscale HTTPS, SOPS credentials, provider and retention settings. The pinned
  upstream exports no Home Manager client module, so client wiring stays here.
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
- The input is pinned to reviewed commit `8f6a15b3a2f622959cfc7659b905fb9701b73bfd`,
  including upstream fixes #1316–#1318 for Markdown section patches, SQLite WAL
  bounds and hook-ledger Git-history amplification. A small Nix-owned source patch
  corrects durable-page concurrency guidance and bounds new TypeScript spool
  entries. Both server and clients use that same patched package and skill source.
- Backend: `127.0.0.1:49374`; no new firewall port or public ingress.
- A foreground Tailscale Serve unit owns only its dedicated HTTPS listener. It
  refuses an occupied port, never resets Serve, and never enables Funnel.
- Data: `/var/lib/ai-memory` (wiki, raw data, SQLite, credentials and history).
- Resource ceiling: 2 GiB, 128 tasks. CPU-only local embeddings use the pinned
  `all-MiniLM-L6-v2` model (384 dimensions, approximately 87 MB download).
- Saradomin enables the built-in web UI. The ChatGPT subscription `openai-oauth`
  backend supplies LLM summaries, with no paid API fallback. Session-end consolidation is enabled;
  the hourly improvement reviewer stages proposals for manual approval.
  Dream processing is enabled for idle-time cold-note consolidation; LLM search
  reranking and cross-project profiles stay off.

These describe the repository configuration, not proof of deployment. Private
service-user ChatGPT login, provider acceptance and native activation checks must
happen separately. The new configuration no longer selects Copilot's bootstrap
EnvironmentFile; legacy ciphertext and existing cache entries are preserved.

`AGENTS.md`, current code and verified tests are authoritative. ai-memory holds
historical evidence and handoffs, not permissions or a replacement instructions
hierarchy. Reviewed architecture stays in ordinary repository documentation.

## Configuration ownership

### Everyday quick reference

| Goal | What to ask or run |
|---|---|
| Start the daily managed workflow | `oc` (alias for `ai-memory run --no-autowire opencode`) |
| Resume work | "Where did we leave off?" |
| Find previous context | "Search memory for how we configured X." |
| Save an intentional decision | "Remember this decision for this project." |
| Leave useful next-session context | "Wrap up with a handoff." |

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

The OpenCode CLI tracks `github:anomalyco/opencode/production`, with
reproducible revisions managed by `flake.lock`, not an explicit commit in the
input URL or the development branch. Update this input deliberately and keep
its V2 adapter aligned.
The feature exports only the CLI, restores the upstream source filter's omitted
`script/` directory, and wraps the CLI through `wrapper-modules`. The sandboxed
hook generator explicitly selects `--agent opencode2`; the V2 plugin is installed
as `opencode/plugins/ai-memory-opencode2.ts`. Home Manager removes its previously
managed V1 plugin link on an approved activation.
The Desktop client is not installed; an approved activation removes its managed
package without deleting its native application data.

**Native-state safety:** this restoration does not migrate, copy, delete or open
existing OpenCode databases, credentials or chats. The temporary Nixpkgs V1
selection used a separate stable-channel database; this configuration does not
merge those chats into V2. Preserve both stores. Before using existing chats
after a package/channel change, separately review/back up native state and test
with isolated HOME/XDG directories. Successful Nix builds do not establish
database compatibility or successful interactive managed capture.

The isolated client check verifies `opencode debug paths db` resolves to
`$XDG_DATA_HOME/opencode/opencode.db`, matching the pinned ai-memory transcript
reader without a downstream database-path patch.

Integration is intentionally **OpenCode-only**. The `ai` profile also installs
Claude Code, Codex and GitHub Copilot CLI, but does not configure ai-memory hooks,
MCP or skills for them. Hermes's own memory is separate. Those clients do not
participate in cross-client capture/recall merely by being installed.

MCP uses the local `ai-memory mcp-bridge --no-session-id`, reading credentials at
runtime and connecting to the shared server. This is a **static** client: pass
both workspace and project on every project-scoped call, even with lifecycle
hooks enabled. The installed workflow instructions explain this requirement.

Do not run `ai-memory setup`, `upgrade`, or live `install-*` commands over managed
configuration. `ai-memory run` must use `--no-autowire`; the session environment
also sets `AI_MEMORY_RUN_AUTOWIRE=false`. Update through flake inputs and rebuild.
Do not substitute an imperative installer or self-update for a Nix change.
See the backup and coordinated upgrade/rollback requirements below before
activating an updated server binary.

The [official individual workflow](https://aimemory.sh/pt-br/solutions/individuals/)
recommends launching through `ai-memory run`; use the command above as the daily
terminal entrypoint. The memory client alone defines the shell alias `oc`; hosts
without that client get no alias. Until Home Manager activation installs it, use
the full command. Direct `opencode` still loads the managed hooks and MCP, but
does not create the same managed workstream, transcript-import and recovery
lifecycle. Managed runs import visible transcripts with capture exclusions;
they are not merely an alternative spelling for direct hook capture. This
launch path has been checked against upstream documentation and installed CLI
options, not live-tested here as an interactive managed run.

The V2 adapter deliberately does not emit `SessionEnd` when its location unloads.
The offline fixture checks delivery/recovery and this non-finalizing unload
behavior; it is not proof of interactive managed capture or production
consolidation. The shared-service V2 lifecycle caveats below still apply with
managed launch. `/memory-finish` remains an explicit recovery command, not daily
usage.

The managed durable-page skill and always-loaded workflow require optimistic
concurrency: read a page and pass its `page_id` as `expected_page_id` on an update
or deletion; use `create_only = true` for a new page. On `precondition_failed`,
re-read and resolve the conflict. A write replaces the whole page and omitted
metadata, not just the requested paragraph.

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

### ChatGPT subscription login and usage

The server uses **`openai-oauth`**, ai-memory's ChatGPT/Codex subscription backend,
not `openai`, which is separately billed API access. It does not use an OpenAI
Platform API key and has no paid-provider fallback. Subscription eligibility,
rate limits, available models, provider terms and account-level spending/data
controls still apply; this is not unlimited or guaranteed access. Captured
observations used for summaries/review leave Saradomin for the provider. Local
embeddings and ordinary search remain on Saradomin.

Keep the single shared memory server. Moving it to each workstation would not
fix provider/model eligibility and would create separate histories to manage.
OpenCode's own model/login is independent of this server's provider login.

**Before activating this configuration**, run the following in your own private
terminal, outside captured agent sessions:

```sh
ssh -t saradomin 'sudo -u ai-memory /run/current-system/sw/bin/ai-memory --data-dir /var/lib/ai-memory auth login openai-oauth'
```

The native flow prints a browser URL and temporary device code; complete it
with the intended ChatGPT subscription account. **Never paste the device code,
URL containing credentials, tokens or auth-file contents into an agent chat.**
Tell the agent only whether login succeeded. Do not run login through an agent
tool, read the real `auth.json`, copy another application's credential file or
put provider credentials into Nix/SOPS configuration.

Login/refresh owns the mutable, service-private `/var/lib/ai-memory/auth.json`.
Keep it owned by `ai-memory`, mode 0600, and inside the protected data directory.
It must remain writable for refresh, never a store symlink or whole-file
SOPS-managed secret. The startup guard rejects missing/unreadable/empty files;
the native provider additionally rejects a file without valid OpenAI OAuth
credentials. Missing login must never silently switch to paid API access.
The SOPS bearer used by memory clients is separate and unchanged.

Then, with explicit probe approval, run a harmless structured-output test in
your private terminal:

```sh
ssh -t saradomin 'sudo -u ai-memory /run/current-system/sw/bin/ai-memory --data-dir /var/lib/ai-memory llm-test --provider openai-oauth --model gpt-6-luna --structured --prompt "Return a short answer"'
```

The configuration explicitly selects **`gpt-6-luna`**, recommended for focused
summarization/extraction in [OpenAI's current Codex model guidance](https://developers.openai.com/codex/models).
Do not inherit ai-memory's stale `gpt-5.5` default: OpenAI retired that model
from Codex with ChatGPT sign-in on October 14, 2026 (API-key access is separate).
The pinned client already omits unsupported temperature overrides for GPT-6.
Availability is still account/client-dependent. The private service-user probe
has passed for `openai-oauth` / `gpt-6-luna`, including structured JSON output;
this confirms provider acceptance, **not production activation**. Repeat the test
after account/model changes rather than relying on a public comparison page. It consumes
subscription allowance but does not restart production. A model failure is not
permission to rotate credentials, delete cache entries or enable API fallback.

The legacy `secrets/ai-memory-copilot.yaml` ciphertext, operator-only
`ai-memory-import-copilot` package and existing Copilot auth-cache entries remain
preserved. They are not selected by the new server role: no Copilot bootstrap
secret or EnvironmentFile is declared, and no Copilot-specific startup guard
remains. Do not run the legacy importer for ChatGPT login or delete its encrypted
credential/runtime history as routine cleanup. The temporary diagnostic code
used during provider evaluation was public-only and unrooted; no diagnostic or
new provider credential is installed in the live service by these changes.

Session-end summaries have a 16,000-token input target and 2,000-token output
limit, with low reasoning effort. Compaction can also queue a summary. Provider
work runs outside hook requests; failures can retry, while deterministic
checkpoints remain available. LLM search reranking is left off so ordinary
recall does not spend subscription allowance.

The improvement scheduler reviews at most one eligible ended session **per
project per hour**, after a ten-minute settling period. A persisted first-run
watermark excludes earlier history; old or terminally failed reviews need an
explicit scoped manual catch-up rather than being assumed to replay forever.
All improvement proposals
require manual approval; they do not automatically rewrite repository files,
skills or `AGENTS.md`. From an opted-in client, inspect this project's queue:

```sh
ai-memory pending-writes list --workspace personal --project nix-config
```

Use `pending-writes show` / `diff` to review a specific proposal before any
explicit `approve` or `reject`. Summaries themselves are generated automatically
and are not approval-gated; treat them as fallible evidence and spot-check them.
Dream processing is separately enabled. With the configured LLM and local
embedder, its upstream scheduler considers a run hourly after five minutes of
inactivity, skips stores without at least two eligible cold pages, and rewrites
at most eight clusters per run. Returning activity cancels work at the next
cluster boundary. These are the pinned upstream defaults, not guarantees that
every idle period produces work. Dream rewrites are **automatic, not gated by
the improvement-proposal approval setting**: they rewrite one cluster member and
supersede the others with merge stubs, preserving the pre-merge versions in
history. This uses subscription allowance and can send eligible note content to
the provider. Cross-session experience synthesis and cross-project profiles
remain off. Dream processing is independent of the session-consolidation queue
shown by the web health page; enabling it does not retry failed session jobs.

#### Consolidation health is separate from capture health

The web health page's **Consolidation** panel counts persisted background session
jobs. `last completed: never` with failed jobs means no tracked queue job has
completed successfully; it does **not** mean hook observations were lost. A
successful provider test or healthy provider indicator is not proof that a full
session rewrite has succeeded. OpenCode's ordinary Stop checkpoint is
deterministic; a real session end or compaction is what can queue LLM work.

Transient failures retry with bounded backoff, up to five worker attempts; an
attempt may itself retry a transient provider call. Malformed, empty or truncated
structured responses can terminate a job earlier; the deterministic checkpoint
remains available. Terminal failures are not automatically reset by enabling
dream or restarting the service. Inspect the saved error before approving a
scoped retry; do not blindly finalize open sessions, reset queue tables, increase
output budgets or change providers. An operator can inspect the redacted worker
failures in a private terminal:

```sh
ssh -t saradomin 'sudo journalctl -u ai-memory.service --since "7 days ago" --grep "queued LLM consolidation" --no-pager'
```

If those logs have rotated away, inspect only the failed queue metadata with a
service-user read-only database query. Do not dump observations, raw provider
responses or authentication files. Failed-job counts are retained history, not a
request to delete the rows to make the health panel green.

### Retention and storage policy

The feature explicitly preserves the upstream defaults rather than changing
retention during this repair:

- Daily forget sweep and lint remain enabled.
- Working/episodic retention uses `lambda = 0.02` and a cold threshold of `0.20`.
  An untouched, default-salience episodic page becomes cold after roughly 80 days;
  use, feedback and explicit page metadata affect this timing. Semantic,
  procedural and pinned pages do not age out through ordinary decay. Explicit
  TTL expiry overrides pins.
- Evicted tombstones/version ancestry have a 180-day grace period before the
  corresponding hard-delete pass. Git history and backups can still contain
  earlier text; retention is not a secure-erasure guarantee.
- Raw-observation pruning remains **off** (`observation_retention_days = 0`):
  raw observations are retained indefinitely. Searchable page retention and raw
  observation retention are separate policies.
- Zero-LLM cold-page compaction/deduplication and profile harvesting stay off;
  the separate LLM dream pass is enabled as described above.

The 2 GiB systemd ceiling limits RAM, not disk. Monitor free disk, database/WAL,
wiki Git history and client spools. The reviewed upstream fixes prevent new
ledger-history amplification and bound WAL handling after compaction; they do
not erase historical ledger blobs or promise a total storage quota. Do not run
history rewriting, compaction or pruning as an automatic part of activation.

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
  through `my.ai.memory.server.tokenFile`. It generates no separate token.
- macbook and zaros: owner is the configured human user, mode **0400**;
  `my.ai.memory.client.tokenFile` forwards the runtime path to Home Manager, which
  creates `<client-data-dir>/auth-token` as an out-of-store symlink. Both the
  OpenCode plugin and MCP bridge follow it. The client data directory is 0700.

Configure workstation endpoints at host level with
`my.ai.memory.client.serverUrl`; the memory feature forwards the typed client
settings to Home Manager on NixOS and Darwin. The `ai` profile imports that
client role alongside the shared coding tools. Server machine facts use
`my.ai.memory.server`, separately from the workstation profile. Feature import
names and upstream `services.ai-memory` options are unchanged.

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

1. Run `oc` (or its full command above) in the opted-in checkout; ask for prior
   context when useful.
2. Search narrowly, verify remembered claims against current files, then work.
3. Ask to save durable knowledge only when intentional; avoid duplicate notes.
4. Ask to **wrap up with a handoff** before changing machines. Closing a TUI or
    evicting an idle OpenCode location does not necessarily end the native session.
5. Commit/push code separately. Memory does not transfer uncommitted changes,
    running processes or the full native OpenCode session.

### OpenCode V2 lifecycle limitation and operator fallback

An **Open** memory session has not received `SessionEnd`; this does not mean its
activity was unsaved. The pinned OpenCode V2 adapter emits a Stop checkpoint and
automatic handoff after a completed root turn. Plugin unload is deliberately not
a session end: OpenCode's shared service can evict an idle location while its
conversations remain resumable. Native session deletion emits an end, but **do
not delete your chats just to close their memory records**.

The managed launcher does **not** remove this limitation in the pinned version:
its exit finalizer covers Command Code, Kiro and Antigravity, not OpenCode V2.
The shared service also prevents the V2 plugin from reliably receiving a
launcher's run environment. Upstream documents ordinary handoff delivery as the
fallback for managed V2 context delivery. See the pinned
[managed-workstreams guide](https://github.com/akitaonrails/ai-memory/blob/8f6a15b3a2f622959cfc7659b905fb9701b73bfd/docs/managed-workstreams.md).
Do not equate a completed workstream leg, a saved checkpoint, successful LLM
consolidation and an ended memory session. Seamless V2 closure remains an
upstream integration gap, not a reason to add a routine manual UUID ritual or
blind idle-session finalizer.

Only when an explicit memory-record close is needed, the operator fallback is
`/memory-finish <ai-memory-session-UUID>` in that conversation. Copy that
conversation's memory UUID from the web UI/session metadata
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

- The Nix-owned TypeScript guard permits at most 4096 directory entries and
  64 KiB per newly serialized event (including its credential envelope). When
  full, it refuses **new** queued events and warns once until capacity returns;
  it never evicts or rewrites the existing backlog. Temporary/foreign entries
  count toward the limit too. Existing oversized entries are preserved. Checks
  occur per write, so concurrent processes may slightly overshoot; this is not
  a filesystem quota. Capture resumes after successful draining frees capacity.
- The native CLI drain has its own age/attempt/count policy. It is not the
  TypeScript guard and can discard entries during operator-run recovery. Do not
  assume indefinite retention or lossless replay merely because the server
  reconnects.

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

The wiki's local Git history is **not a backup**. A prepared backup module is
not evidence of provisioning, a successful off-host snapshot or a tested restore.
Before relying on the service, approve an encrypted off-host backup target,
retention and a consistent snapshot procedure covering the **whole data
directory**, including auth material, not just SQLite indexes or wiki files.
Test a restore separately without exposing it or starting a second writer.
Rebuilding Nix restores software/configuration, not lost runtime memory.

SQLite is only partly derived: sessions, observations, handoffs, users/API-key
state and audit records cannot be recreated from Markdown by `reindex`. The
upstream Git-mirror example must not be copied unchanged: its tarball excludes
the database, and its exclusions do not cover every bearer/spool path. Never
push credentials, hook spools or database state to an ordinary Git mirror.
Native `ai-memory backup` supplies a coherent database snapshot plus wiki/config,
but not the entire `raw/` tree, mutable provider cache or external SOPS inputs;
it alone is not a full disaster-recovery plan.

### Prepared Restic/R2 backup

Saradomin explicitly selects the NixOS-only `ai-memory-backup` aspect. It does
**nothing operational** until both `my.restic.ai-memory.repositoryFile` and
`passwordFile` are configured: no Restic job, timer, new required secret,
initialization, upload, restore or ai-memory restart is created by the current
unprovisioned selection. The existing Zaros Restic feature and its policy are
unchanged.

Use a dedicated R2 Restic repository/prefix and password. After separately
provisioning the named values in the existing encrypted SOPS source, a host
configuration can reference their runtime paths:

```nix
sops.secrets."restic/saradomin/ai-memory/repository" = { };
sops.secrets."restic/saradomin/ai-memory/password" = { };
my.restic.ai-memory = {
  repositoryFile = config.sops.secrets."restic/saradomin/ai-memory/repository".path;
  passwordFile = config.sops.secrets."restic/saradomin/ai-memory/password".path;
};
```

When configured, the feature reuses the existing SOPS `restic/r2-env` credential
pattern, unless `my.restic.ai-memory.environmentFile` supplies another private
runtime EnvironmentFile. R2 region and path-style lookup match the existing
Restic integration. All credential settings reject Nix store paths. Do not
reuse a broad repository or expose credentials in arguments, logs or the store.

The native `services.restic.backups.ai-memory` job remains **manual-only**, with
`initialize = false`, no timer, no pruning and no credential-loading wrapper.
Repository initialization, the first backup, retention/scheduling and activation
each require deliberate approval; this preparation performs none of them.

The job runs as root and uses Restic's `--stdin-from-command` to store one
encrypted `ai-memory-full.tar` artifact. Its producer:

- Streams the full data tree, including hidden wiki Git history, raw data,
  pending proposals, mutable provider auth, logs, models and unknown regular
  files. No plaintext full archive is saved on local disk.
- Replaces the live SQLite database/WAL/SHM/journal with a validated online
  SQLite snapshot. Only that temporary database is staged under root-only
  `/var/lib/ai-memory-backup` (0700, umask 0077), and the producer removes its
  own temporary directory after success or failure. It never deletes source
  data or an existing Restic snapshot.
- Excludes transient `.serve.lock*` files; refuses symlinks, special files,
  unreadable directories, unexpected additional databases and detected
  per-file copy races. A failed producer makes Restic reject the new snapshot;
  isolated tests exercise that contract and preservation of an older snapshot.
- Includes a private manifest describing its layout and limits. SQLite is
  transactionally consistent, but the other files are copied live: **this is
  not an atomic point-in-time snapshot of the entire application**. Saradomin
  currently has no configured filesystem snapshot layer. Stronger cross-file
  consistency needs a separately approved quiesce/snapshot design, not a false
  claim that copying a live directory is atomic.

The artifact's layout is `data/` plus `backup-manifest.json`; it is not a native
`ai-memory restore` archive. Recovery must first restore/dump the artifact into
a private location, validate/extract it without trusting unsafe archive paths,
and restore service ownership/permissions while the production service is
separately approved to be stopped. Never print the archive to a captured terminal.
External SOPS credentials, the age identity and Nix configuration are not inside
the data tree; preserve their existing secure recovery procedures separately.

Remaining provisioning gates: choose and restrict the R2 destination, provision
dedicated encrypted repository/password values, initialize only with approval,
perform an approved first off-host backup, and test recovery. There is currently
**no configured or verified production backup**.

### Coordinated upgrades and rollback

1. Before an approved server upgrade, take and verify an encrypted off-host
   snapshot of runtime state, record the deployed generation/package path and
   preserve access to the old binary. Verify recovery in a private isolated
   environment before relying on it; do not expose a second live writer.
2. Review the selected commit, local source patch and migration notes; build on
   native Linux and validate clients before separately approving activation.
3. Do not assume a Nix-generation rollback reverses data changes. Migrations are
   forward-only; an older binary may refuse the newer schema/wiki format.
4. If data rollback is necessary, separately approve stopping the service and
   restoring the matching pre-upgrade snapshot with the **old** binary. Using
   a newer binary to restore can migrate that snapshot forward again. Preserve
   the current state separately before replacement; post-snapshot writes and
   credential changes would otherwise be lost.
5. Confirm credentials, integrity, authenticated HTTPS and scoped capture/recall
   before resuming normal clients. Never clear queues, reset data or rewrite Git
   history merely to make the old binary start.

Native server and two-machine HTTPS/auth/capture/recall checks, occupied-port
behavior, reboot persistence and backup/restore verification remain deployment
acceptance gates. Build-time mocks do not verify live tailnet state.
