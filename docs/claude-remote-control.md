# Claude Remote Control on Zaros

Zaros explicitly selects `claude-remote-control`, a lingering systemd user service.
It runs the upstream Claude Code package in `~/repos`, with normal permission
checks and no inbound listener. MacBook and server hosts do not select it.
Override `my.ai.claude.remoteControl.directory` in Home Manager to use a different
existing directory. Selecting this feature explicitly trusts that directory and
accepts Remote Control consent. A pre-start merge sets only
`projects[<directory>].hasTrustDialogAccepted` and `remoteDialogSeen` in mutable
Claude state, preserving login metadata, other projects and permission settings.
It refuses malformed state, symlinks and active writer locks rather than
overwriting them. No credentials are put in the Nix store.
Remote sessions share that directory; avoid concurrent edits
to the same files. Claude can access files as your user, so review permissions
carefully. Remote transcripts are synced through Anthropic.

The service bypasses Home Manager's CLI plugin wrapper: server mode cannot
forward its injected `--plugin-dir` arguments. On-disk settings and skills still
apply, but wrapper-provided plugins (including the shared MCP registry plugin)
do not. Do not assume those MCP servers are available remotely.

## First-time setup

In a private terminal on Zaros, sign into Claude Code with your eligible Claude
subscription:

```sh
claude auth login
```

Directory trust and Remote Control consent are managed by the feature; no
interactive trust setup is needed. Do not use API-key auth or a restricted
`claude setup-token` token for this.
No credentials are managed or copied by this feature.

After an explicitly approved configuration activation, inspect the service with:

```sh
systemctl --user status claude-remote-control
```

Open Claude's mobile app or https://claude.ai/code using the same account to
connect. The service creates no initial conversation; start sessions remotely.
Zaros must remain awake and online. Lingering keeps the user service running
after logout, but does not prevent suspend.

The service retries failures every 30 seconds, bounded to three starts per five
minutes so missing authentication or consent cannot cause an unbounded crash
loop. After fixing setup, explicitly restart it with:

```sh
systemctl --user reset-failed claude-remote-control
systemctl --user restart claude-remote-control
```

Treat service logs as private: they can contain session connection URLs. Native
subscription authentication and mobile connection are manual acceptance checks;
a successful Nix build does not verify either.
