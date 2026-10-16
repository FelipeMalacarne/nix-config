# Claude Remote Control on Zaros

Zaros explicitly selects `claude-remote-control`, a lingering systemd user service.
It runs the upstream Claude Code package in `~/repos`, with normal permission
checks and no inbound listener. MacBook and server hosts do not select it.
Override `my.ai.claude.remoteControl.directory` in Home Manager to use a different
existing directory. Remote sessions share that directory; avoid concurrent edits
to the same files. Claude can access files as your user, so review permissions
carefully. Remote transcripts are synced through Anthropic.

The service bypasses Home Manager's CLI plugin wrapper: server mode cannot
forward its injected `--plugin-dir` arguments. Shared on-disk Claude settings,
MCP configuration and skills still apply, but wrapper-only plugins do not.

## First-time setup

In a private terminal on Zaros, sign into Claude Code with your eligible Claude
subscription. Build the unwrapped, pinned CLI and run it directly (the usual
`claude` command injects plugin flags):

```sh
# From the nix-config checkout:
claude_bin=$(nix build --no-link --print-out-paths --impure --expr '(builtins.getFlake (toString ./.)).inputs.nixpkgs.legacyPackages.x86_64-linux.claude-code')
cd ~/repos
"$claude_bin/bin/claude" remote-control --name zaros --no-create-session-in-dir
```

Accept Remote Control consent and directory trust yourself. Confirm that the
server connects, then stop it with Ctrl-C before starting the background service.
Do not use API-key auth or a restricted `claude setup-token` token for this.
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
