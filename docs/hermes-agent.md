# Hermes Agent

Zaros selects `my.hermes-agent.enable = true`. The optional-feature catalog
exposes the option on NixOS, disabled by default. The implementation lives in
`modules/features/programs/hermes-agent.nix`, not in the general programming
package list.

## Ownership

- Home Manager imports upstream `homeManagerModules.default` for both
  `programs.hermes-agent` and `services.hermes-agent`.
- The CLI, desktop launcher and dashboard use the account's existing `~/.hermes`.
- `hermes-backend.service` is a **user** service. NixOS enables account linger so
  it continues after logout. No system-wide Hermes account/service is created.
- The dashboard listens on `http://127.0.0.1:9119`. No firewall ports are opened.
- The messaging gateway is disabled. Enable the Home Manager option
  `services.hermes-agent.gateway.enable` separately if needed.

The desktop connects to the managed dashboard backend using
`services.hermes-agent.backend.sessionTokenFile`. Activation generates
`~/.hermes/.backend-session-token` locally with mode `0600`, before Home Manager
reloads user services. Creation is atomic and later rebuilds keep the same token.
Both launchers read it at runtime; its value never enters the Nix store or the
repository. Empty, symlinked, or non-regular token files fail setup rather than
being silently replaced. An explicitly configured alternative token path (for
example SOPS) is caller-managed; this feature does not create or change it.

## Private web access over Tailscale

Zaros also enables `my.hermes-agent.web`. The implementation is in
`modules/features/programs/hermes-agent/config/web.nix` and is disabled by
default on other hosts. Its host declaration is:

```nix
my.hermes-agent.web = {
  enable = true;
  publicUrl = "https://zaros.osiris-fish.ts.net";
  environmentFile = config.sops.secrets.hermes-web.path;
  restartTriggers = [ ../../secrets/hermes-web.yaml ];
};
```

The host's actual secret declarations are conditional on both Hermes and web
access being enabled. The public URL must match the device's real Tailscale DNS
name; the proxy checks it rather than silently serving a different machine URL.

### Ports and ownership

- The existing **user** `hermes-backend.service` stays on `127.0.0.1:9119`, with
  the same shared token and desktop launcher.
- A second **user** `hermes-web.service` runs the same Nix-built Hermes package
  against the same writable `~/.hermes`, on `127.0.0.1:9120` by default. It has
  password authentication. `my.hermes-agent.web.port` changes this internal port.
- The **system** `hermes-tailnet.service` runs Tailscale Serve in the foreground.
  It forwards tailnet-only HTTPS to the authenticated web listener. It does not
  run another agent account, open a LAN/public firewall port, or enable Funnel.

The URL and login environment are scoped to the web service. They are not
written into the shared `config.yaml` or `.env`: a shared non-loopback
`dashboard.public_url` would engage the auth gate on the private Desktop
backend and break its token-based connection. Both listeners share persisted
configuration, skills, memory and session history, not in-flight process state.
Avoid operating the same conversation concurrently through both listeners.

An omitted URL port means HTTPS port 443. To leave 443 available for another
application, change only:

```nix
my.hermes-agent.web.publicUrl = "https://zaros.osiris-fish.ts.net:8443";
```

This configures HTTPS on 8443 while the internal listener remains on 9120.
Other applications can use other HTTPS ports on the same machine. Paths such
as `/hermes/` and named Tailscale Services are intentionally outside this feature.
Hermes session cookies are scoped to the hostname with `Path=/`, so other HTTPS
ports on that hostname must be equally trusted. Port separation is not a
credential-isolation boundary.

The proxy refuses to replace an existing route on its selected HTTPS port,
including routes owned by another foreground process. It leaves other ports
alone. It checks Tailscale login, the expected DNS name and the dashboard's
active auth gate before publishing. Failed readiness checks retry after five
seconds; a user service cannot be ordered after a system service directly.

No persistent `--bg` route or global `serve reset` is used. Stopping/removing
this service interrupts its foreground Serve process, which removes its route.
The unit restarts even after a clean foreground Serve exit because Tailscale can
report watcher EOF as success while the daemon continues running. Explicit
manager stops still suppress restarts. The unit also follows Tailscale daemon
restarts. Setting
`my.hermes-agent.web.enable = false` and activating removes both web units and
Zaros's decrypted web secret, while preserving the desktop backend and encrypted
credential source. Actual HTTPS access requires the machine to be awake.

### Login and encrypted credentials

The login username is `my.user.name` (`felipe` on Zaros). The generated password
is encrypted in `secrets/hermes-web.yaml` using the repository's existing SOPS
recipient. View it **in your own trusted terminal**, not in agent/chat output:

```sh
SOPS_AGE_KEY_FILE=/var/lib/sops-age/keys.txt \
  sops decrypt --extract '["password"]' secrets/hermes-web.yaml
```

The encrypted `environment` field contains the scrypt password hash and a stable
session-signing secret. SOPS delivers only that field to `/run/secrets/hermes-web`,
owned by the account with mode `0400`. Systemd reads it as an `EnvironmentFile`;
it is not an upstream `services.hermes-agent.environmentFiles` input and never
reconstructs the existing `.env`. The plaintext password is not deployed.

Only non-secret or encrypted inputs belong in `restartTriggers`; changes make
Home Manager restart the web unit on activation, so rotated credentials take
effect. A caller using another secret manager must arrange equivalent restart
triggers. When rotating the password, update its encrypted recovery value and
corresponding hash together. Keep the signing secret stable to preserve login
sessions, or rotate it deliberately to invalidate them.

This is an administrator dashboard, not a read-only chat share. Restrict the
chosen port with tailnet access rules and protect the login accordingly.

### Activation and checks

After review and explicit approval, activate normally with
`make switch HOST=zaros`. The device must already be enrolled in Tailscale, and HTTPS must be
enabled for the tailnet. Those account-level settings are not changed by this
module. Do not manually start a second persistent Serve route for the same port.

Check after activation:

```sh
systemctl --user status hermes-backend.service hermes-web.service
systemctl status hermes-tailnet.service
tailscale serve status
```

Open the configured HTTPS URL from another authorized Tailscale-connected device
and sign in. If it does not start, inspect `journalctl -u hermes-tailnet.service`
and `journalctl --user -u hermes-web.service`. A mismatched DNS name, occupied
HTTPS port, missing secret, logged-out device or missing HTTPS permission must
be resolved rather than bypassing the guards.

`checks.x86_64-linux.hermes-web` evaluates enabled/disabled hosts, alternative
HTTPS ports, private credential delivery, unchanged firewall policy and rejected
invalid configurations. `checks.x86_64-linux.hermes-web-runtime` launches the
actual Nix-built private and web backends with disposable state. It checks
password login, HTTPS cookies, unauthenticated rejection, authenticated chat
WebSockets, ticket replay, host/origin guards, restart-surviving sessions and
Desktop token compatibility, for both default and non-default HTTPS origins.
The proxy preflight is exercised with explicit stub CLI/HTTP fixtures; these
checks do not publish anything to the live tailnet or prove remote TLS access.

The `hermes-agent` integration check also verifies the repository's declared
approval policy; the web feature does not alter it.

## Configuration and credentials

The feature preserves the selected model, `openai/gpt-5.6-sol`. Home Manager
merges declared settings into the writable config on activation; undeclared
settings are preserved. The upstream managed-mode marker makes some interactive
configuration commands refuse changes, so change Nix-managed settings here and
rebuild.

The declared baseline enables memory and user-profile learning, secret redaction,
verification-on-stop and filesystem checkpoints. `approvals.mode = "smart"`
assesses flagged commands automatically and prompts when uncertain; it does not
require a human decision for every flagged command.
`skills.write_approval = true` stages agent skill changes for review; use
`/skills pending` and `/skills diff <id>` before approving a proposed lesson.
These safeguards are not a sandbox, a backup, or a substitute for Git and Nix
generations. Automatic deployment and scheduled jobs are not enabled.

The backend receives Nix, nixfmt, Make, Git, jq, ripgrep, fd, uv, curl and (on
Linux) systemctl through `services.hermes-agent.extraPackages`. Project-specific
dependencies still belong in project dev shells. Do not install Python packages
into the immutable Hermes runtime or system Python.

## Writable learning

Activation seeds `~/.hermes/skills/nix-system-workflow/SKILL.md` as an ordinary,
private writable file, only when absent. The seed is versioned under
`modules/features/programs/hermes-agent/config/nix-system-workflow/SKILL.md`.
Existing skills, memories and local improvements are not overwritten on rebuild.
Updates to the seed must be reviewed and merged deliberately into an existing
runtime copy. This also means a previously archived or intentionally removed
seed will be restored if it is absent at the next activation.

Select the repository root as the desktop project so its `AGENTS.md` supplies
machine-specific rules. The skill supplies reusable Nix workflows across
projects; memory is for small durable facts, not task logs. Keep learning and
OAuth state writable under the active Hermes home, not declaratively installed
via `hermesHomeFiles`.

`environment`, `environmentFiles` and `authFile` are intentionally unset. Existing
`.env` and OAuth credentials are not replaced by activation. If credentials are
later moved to SOPS, use runtime string paths. Upstream reconstructs `.env` when
`environment` or `environmentFiles` is set; do not use `~/.hermes/.env` itself as
an input to that operation.

## Dependency pin

Hermes keeps its own nixpkgs input. Its desktop package has a fixed Electron
header checksum but selects the header URL using `electron.version`. Making
Hermes follow the system nixpkgs can therefore break the desktop build.

When changing the Hermes revision, retain the nixpkgs revision from that
revision's upstream `flake.lock`. Removing a previous `follows` override alone
can select the latest nixpkgs rather than restoring the upstream lock. Restore
the upstream revision with:

    nix flake lock --override-input hermes-agent/nixpkgs github:NixOS/nixpkgs/<upstream-locked-revision>

The Hermes integration check enforces this pairing. Do not work around header
mismatches by blindly accepting the reported replacement hash.

## Validation and activation

    make fmt-check
    make eval-check
    make check

These do not activate the configuration. After a successful build:

    make switch HOST=zaros
    systemctl --user status hermes-backend.service

The desktop launcher is `hermes-desktop`; the CLI is `hermes`. No provider API
call is needed to evaluate or build the configuration.

After activation, close and reopen the desktop application to pick up the new
launcher and shared-backend connection. Existing running desktop processes are
not rerouted automatically. No activation or service restart is performed by
the flake checks.

`checks.x86_64-linux.hermes-agent` checks settings, activation order, package
availability, credentials preservation and disabled hosts.
`checks.x86_64-linux.hermes-runtime-state` exercises disposable token/skill
initialization and inspects the generated desktop/backend launchers.
