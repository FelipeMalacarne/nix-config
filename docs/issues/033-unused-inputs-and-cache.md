# ISSUE-033: Audit unused flake inputs and the NVF cache policy

- Status: resolved
- Priority: P3
- Kind: optional dependency and trust-policy cleanup
- Scope: flake inputs, lock graph, and shared cache settings
- Dependencies: none; coordinate with [ISSUE-035](035-core-dependency-update.md)

## Problem And Evidence

The [flake](../../flake.nix) still declares `nvf` and `nvim-config`. The reviewed
[editor implementation](../../modules/features/programs/neovim/neovim.nix) uses
wrapper-modules and local configuration, with no discovered consumer of those
two inputs. Shared [NixOS](../../modules/features/system/core/config/nixos.nix)
and [Darwin](../../modules/features/system/core/config/darwin.nix) policy retains
the NVF substituter and trusted public key.

## Decision And Scope

Confirm indirect consumers, deliberate developer uses, and whether the cache
still provides useful trusted artifacts before removing anything. Remove only
inputs/cache configuration no longer wanted. Unused inputs complicate updates
but do not automatically mean duplicated installed packages or large savings.
Do not deduplicate Hermes's intentionally independent Nixpkgs input.

## Acceptance Criteria

- [ ] Remaining consumers and intended standalone uses of each candidate are checked.
- [ ] Unused inputs are removed from the declaration and lock graph together.
- [ ] The NVF cache/key is either justified or removed consistently on supported platforms.
- [ ] Retained package outputs and host configurations still evaluate without hidden input dependencies.

## Verification And Approval

Inspect the actual dependency graph, update only the intended lock nodes, run
format/evaluation checks, and build affected outputs on their native platforms.
Cache-policy edits must be deliberately reviewed; do not change unrelated
substituters, trust keys, or application selections. Do not promise reclaimed
space without measuring references and GC roots separately.

## Resolution

Removed the unused `nvf` and `nvim-config` inputs, the NVF substituter and key on both platforms, and refreshed `flake.lock` (removals only). Evaluation and checks pass.

[Back to backlog](README.md)
