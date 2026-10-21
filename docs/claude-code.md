# Claude Code settings

Nix manages the Claude package, MCP integrations, skills, rules and a settings
baseline. Claude owns the writable `~/.claude/settings.json`, so `/effort`,
`/model`, `/config` and plugin preferences can persist without writing into the
Nix store. A custom `programs.claude-code.configDir` uses the same layout.

Continue declaring baseline settings through `programs.claude-code.settings`.
Home Manager renders the complete upstream JSON as `settings.nix.json`. During
activation, a feature-local helper compares the previous baseline, current user
settings and new baseline:

- Unchanged defaults follow Nix updates, including removal of obsolete defaults.
- Local changes, additional keys and deliberate deletions survive rebuilds.
- Nested objects merge by key; locally changed arrays are preserved as a whole.
- On first use, existing preferences win and missing defaults are added.

These are defaults, not managed enterprise policy. A local override wins even
when Nix changes that default later. To reset one, set its value to the current
`settings.nix.json` baseline; subsequent Nix changes can then update it. Deleting
the key is a local override, not a reset. An absent settings file is seeded from
the current baseline.

The first approved activation converts only a recognized Home Manager settings
symlink into a private (`0600`) regular file. It does not modify the Nix store or
touch Claude's credentials, transcripts or `~/.claude.json`. Invalid JSON,
unrecognized symlinks and detected concurrent edits fail instead of being
overwritten. Keep Claude idle during activation: the concurrency checks are
best-effort, not a transaction with Claude's own writer. Dry runs do not write.

This change needs a separately approved activation. Until then, the existing
read-only settings remain; `claude --effort high` is a session-only workaround.
Interactive `/effort` and cross-session persistence remain manual acceptance
checks after activation. Rolling back to the former immutable configuration may
produce a Home Manager file collision; preserve the writable file privately
before choosing how to restore that generation. Do not force-overwrite it.

See [Remote Control](claude-remote-control.md) for Zaros's separately selected
service and its authentication/consent requirements.
