# Chronicle agent

`chronicle agent` is the Microbot control agent of
[Chronicle](https://github.com/FelipeMalacarne/chronicle) (its docs/08). It runs on
the machine with the game, opens an outbound websocket to the planner and runs
only its closed list of commands against the harness's dev client. The planner
never connects to the workstation.

## Aspects

`modules/features/applications/chronicle/` registers:

- `homeManager.chronicle`: the `chronicle` CLI from the `chronicle` flake input.
- `nixos.chronicle-agent`: the companion a host imports. It imports `sops`,
  decrypts the Zitadel machine user's client secret to
  `/run/secrets/chronicle-agent-client-secret` (owner the primary user, mode
  `0400`), enables lingering and forwards the Home Manager aspect with its
  settings.
- `homeManager.chronicle-agent`: the `chronicle-agent` systemd user service. It
  imports `chronicle`.

Settings live in `my.chronicle.agent` on the host:

| Option | Default | Environment |
|---|---|---|
| `serverUrl` | `https://chronicle.saradomin.ftm.dev.br` | `CHRONICLE_URL` |
| `clientId` | required | `MICROBOT_AGENT_CLIENT_ID` |
| `account` | `null` (declares none) | `MICROBOT_AGENT_ACCOUNT` |
| `harnessDir` | `~/repos/chronicle` | `MICROBOT_HARNESS_DIR`, working directory |
| `secret.sopsFile` | `secrets/chronicle-agent.yaml` | |
| `secret.key` | `client-secret` | |

The service receives the secret as `MICROBOT_AGENT_CLIENT_SECRET_FILE`, a path;
neither the secret nor its plaintext enters the Nix store or the environment.

## Runtime

The service runs `chronicle agent` from `harnessDir`, as `just agent` does, under
`default.target`. With lingering it starts at boot, without a login session.
The agent starts the client with `nix develop <harnessDir>#microbot --command
<harnessDir>/microbot/bin/mb-client start --headless`: the game gets its own
Xvfb display (`:99`) and x11vnc on `127.0.0.1:5999`, so the service needs no
graphical session. Its `PATH` holds what the harness needs beyond its dev shell:
Nix, Git, `setsid` and PipeWire's tools to mute the headless client.

`harnessDir` must be a writable checkout of the chronicle repository:
`mb-client` builds the DevBootstrap plugin there. The agent runs whatever that
checkout has checked out.

The agent reconnects to the planner by itself and exits only on a startup
error, such as a missing secret. Systemd then restarts it with a backoff from 5
seconds up to 5 minutes, without a start limit. `KillMode=process` stops only
the agent: the game client it detached keeps running across agent stops,
restarts and Home Manager switches. Stop the game from the planner or with
`mb-client stop`. A change to the encrypted secret file restarts the agent,
which reads the secret once at start.

## Enabling

The aspect needs the secret before a host imports it; evaluation fails while
`secrets/chronicle-agent.yaml` is missing.

1. In Zitadel, create a machine user in the Chronicle project, grant it the
   `microbot:agent` role and generate a client secret. Its client id is the
   machine user's user name.
2. Store the secret with `sops secrets/chronicle-agent.yaml`, under the key
   `client-secret`. `.sops.yaml` already covers `secrets/*.yaml`.
3. Import `self.modules.nixos.chronicle-agent` in the host and set at least
   `my.chronicle.agent.clientId` (and `account` to declare one).
4. Build, then activate with an approved `make switch HOST=zaros`.

Inspect it with `systemctl --user status chronicle-agent` and
`journalctl --user -u chronicle-agent`. `systemctl --user stop chronicle-agent`
cuts the planner's control without closing the game. The binary comes from the
`chronicle` input: `nix flake update chronicle` keeps it in step with the
planner.
