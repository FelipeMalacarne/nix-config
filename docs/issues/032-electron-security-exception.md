# ISSUE-032: Remove or justify the global Electron 39 exception

- Status: resolved
- Priority: P2
- Kind: stale security-policy exception; active vulnerable runtime not established
- Scope: shared NixOS package policy and any actual consuming features
- Dependencies: none

## Problem And Evidence

[Shared NixOS core](../../modules/features/system/core/config/nixos.nix) permits
`electron-39.8.10`, which its pinned package metadata marks end-of-life. This
allowance applies to headless hosts too and has no documented consumer or
retirement condition. The review found no matching version in the inspected
Zaros closure. The exception itself does not install Electron.

## Decision And Scope

Recheck all supported host and intentionally maintained optional-feature
configurations. Remove the exception if stale. If temporarily necessary, identify
the consumer and scope/document the exception rather than approving it globally.
Do not replace it with a broad insecure-package allowance or force an incompatible
Electron version into an application to make evaluation pass.

## Acceptance Criteria

- [ ] Any current consumer of the exception is identified, or its absence is established.
- [ ] The global exception is removed or replaced with a justified, narrowly scoped policy.
- [ ] Any retained allowance records its reason and a removal/update condition.
- [ ] Supported host and relevant optional-feature configurations still evaluate and build.

## Verification And Approval

Evaluate with the exception removed in the proposed change, inspect dependency
paths for any resulting failure, and run affected checks and closure builds.
Do not infer runtime insecurity solely from the whitelist or silently weaken Nix
security checks. Package updates and deployment remain separate decisions.

## Resolution

Removed the stale `electron-39.8.10` insecure-package exception from shared NixOS core. All NixOS evaluations and `nix flake check` pass without it.

[Back to backlog](README.md)
