# ISSUE-036: Update CI actions to supported runtime versions

- Status: resolved
- Priority: P2
- Kind: maintenance warning confirmed in CI logs
- Scope: GitHub Actions dependencies and native platform verification
- Dependencies: [ISSUE-001](001-clean-flake-sources.md), [ISSUE-002](002-desktop-selection-checks.md) for a green end-to-end baseline

## Problem And Evidence

The [workflow](../../.github/workflows/check.yml) uses `actions/checkout@v4` and
`DeterminateSystems/nix-installer-action@v19`. Reviewed CI logs report Node 20
deprecation/forced-runtime warnings. At review time, releases
[checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1) and
[installer v23](https://github.com/DeterminateSystems/nix-installer-action/releases/tag/v23)
were available; recheck supported releases before choosing the implementation.

## Decision And Scope

Review migration notes, runner compatibility, credential persistence, and action
pinning policy. Upgrade the selected actions without changing Nix inputs or
deployment behavior in the same issue. Keep Linux and Apple-Silicon macOS jobs
native and ensure they actually exercise their intended flake checks.

## Acceptance Criteria

- [ ] Selected action versions use a supported Node/runtime combination on both runners.
- [ ] Checkout/authentication and installer behavior are reviewed for relevant migration changes.
- [ ] CI completes the intended checks rather than merely installing Nix successfully.
- [ ] Action pins and any remaining warnings are explicitly documented or justified.

## Verification And Approval

Review workflow syntax and test the updated jobs through normal CI after an
approved commit/push or PR workflow. Do not print credentials or publish copied
Git metadata as an artifact. Documentation of this issue does not authorize a
commit, push, secret change, or deployment; baseline failures remain separate.

## Resolution

Stale: CI already uses `actions/checkout@v5` and `cachix/install-nix-action@v31`.

[Back to backlog](README.md)
