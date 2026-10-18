# ISSUE-014: Align enabled LSP configurations with their runtime servers

- Status: resolved
- Priority: P2
- Kind: source-confirmed configuration mismatch
- Scope: shared Neovim configuration
- Dependencies: none

## Problem And Evidence

The [enabled LSP list](../../modules/features/programs/neovim/config/lsp.lua)
uses `docker-language-server`, whereas the pinned nvim-lspconfig configuration
is named `docker_language_server`. The executable name and configuration name
are not interchangeable. The list also enables `texlab`, but its package is
commented out in [runtimePkgs](../../modules/features/programs/neovim/neovim.nix).
An imperative installation can mask the missing executable.

## Decision And Scope

Correct the Docker configuration identifier. Decide whether LaTeX support is
intended: either package its server or remove the enabled configuration. Do not
add the full TeX distribution by default just to silence a missing-server error.
Broader editor-size changes belong to [ISSUE-030](030-lean-base-neovim.md).

## Acceptance Criteria

- [ ] Every enabled LSP configuration exists in the pinned runtime.
- [ ] Docker files can attach the packaged Docker server under the correct name.
- [ ] Texlab is either deliberately available or no longer enabled.
- [ ] A clean, isolated editor check does not depend on user-installed servers.

## Verification And Approval

Build the wrapped editor and run isolated headless configuration checks with
temporary XDG/state directories. Test attachment against disposable project
fixtures; do not open or modify personal projects. Build affected host closures
under the shared verification policy, including a native Darwin build for
cross-platform runtime changes. No live editor process needs to be restarted.

## Resolution

Already fixed: `docker_language_server` is packaged, `texlab` is no longer enabled, and `check.lua` asserts each enabled server has a `cmd`.

[Back to backlog](README.md)
