# ISSUE-030: Evaluate a smaller editor runtime for headless base profiles

- Status: resolved
- Priority: P3
- Kind: optional package-policy and closure optimization
- Scope: base/server editor composition and development tooling
- Dependencies: coordinate correctness fixes with [ISSUE-014](014-neovim-lsp-configuration.md)

## Problem And Evidence

The [base](../../modules/profiles/base.nix) and
[server](../../modules/profiles/server.nix) profiles include the shared Neovim
runtime. Its [package definition](../../modules/features/programs/neovim/neovim.nix)
unconditionally installs broad LSP/formatter/TUI tooling and all Tree-sitter
grammars. Some packaged tools have no enabled/configured consumer. This increases
headless downloads and closure size; it is not evidence of duplicate store copies.

## Decision And Scope

Confirm which editor capabilities are useful over SSH. Consider a lean base
runtime with explicitly selected development additions, or simply remove unused
tools first. Keep the editor usable and avoid a large architecture rewrite or
new compatibility layer. Project-specific toolchains may belong in dev shells.

## Acceptance Criteria

- [ ] Intended server and workstation editor capabilities are agreed and documented.
- [ ] Enabled plugins, LSPs, and formatters have the executables they require.
- [ ] Before/after server closure sizes and tool selections are compared.
- [ ] Linux and Darwin development configurations retain their intended editor behavior.

## Verification And Approval

Build the selected editor variants, exercise isolated headless startup and
representative disposable files, and build affected host closures. Inspect
generated runtime paths instead of relying on interactive shell tools. Package
optimization does not authorize activation, removal of live development data,
or changes to application/server services.

## Resolution

Already implemented: `neovim-minimal`/`full`/`dev` variants, with the `neovim-selection` check pinning the headless hosts to minimal.

[Back to backlog](README.md)
