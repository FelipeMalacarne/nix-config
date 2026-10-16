---
name: nix-feature-integration
description: Add or refactor a feature in this repository's dendritic flake-parts modules, including explicit host/profile selection, NixOS/Darwin/Home Manager composition and independent-selection checks.
---

# Integrate a Nix feature

Use this procedure for a new aspect or composition change in nix-config. For a
single setting change, use the existing feature instead of creating a new layer.
Run commands from the repository root. `AGENTS.md` defines the architecture;
`references/example.md` gives an implementation and test pattern.

## 1. Find the right boundary

Inspect the nearest feature, the selecting profile and the target host. Follow
these concrete examples as needed:

| Need | Source to inspect |
| --- | --- |
| Small Home Manager feature | `modules/features/programs/btop.nix` |
| Typed machine-specific setting | `modules/features/services/wol.nix` |
| Shared dependency consumed by two clients | `modules/features/programs/playwright-mcp.nix` and its client imports |
| Platform-to-HM profile forwarding | `modules/profiles/ai.nix` |
| Multi-platform feature with internal files | `modules/features/services/ai-memory/` |
| Independent client/profile checks | `modules/profiles/config/test-ai.nix` |

Resolve upstream option types before writing raw config. Inspect the pinned
module source, not a random online version. Register only supported platforms.

## 2. Implement and select separately

1. Add the discovered entrypoint under `modules/features/<domain>/`. Put internal
   Nix helpers in its excluded `config/` directory and import them explicitly.
2. Register the reusable module under `flake.modules.<platform>.<aspect>`.
   Importing that module activates it; do not add a second feature-enable flag.
3. For platform forwarding, capture the outer flake-parts registry and import
   its final Home Manager aggregate. Do not confuse outer `config` with the
   inner platform/HM configuration; see the reference example.
4. Select the aspect in the appropriate profile or host. The host owns machine
   facts. A feature never imports a host or profile.
5. If the platform profile already forwards its HM composition, do not repeat
   the HM profile import in the host. Keep user-only selections explicit.

## 3. Prove the composition

For a composition change, evaluate at least: feature absent, feature selected
alone, and feature combined with its real profile. Assert the observable native
options and required dependencies, plus absence of unintended optional clients.
Test a setting override when exposing a typed interface. Build the generated
configuration or run its native parser when evaluation alone cannot validate it.

Keep synthetic checks beside the feature; reuse
`modules/checks/config/fixtures.nix` where appropriate. Concrete machine
expectations belong in repository/profile checks rather than reusable features.
See the reference for a small standalone Home Manager fixture.

## 4. Validate the affected outputs

```sh
make fmt
make fmt-check
make eval-check
```

Build the specific new/affected check, then the affected host closure. On this
Mac use `make build-darwin`; on native Linux use `make build-all` or
`make build HOST=zaros` when Zaros is the only affected host. A Darwin build is
not a Linux build. `make check` exercises native flake checks and can expose
unrelated baseline failures; identify those separately with file/line evidence.

Report formatting, evaluation, checks and closure builds individually. Do not
turn a successful build into an activation: switch/test/boot and remote
deployment require separate approval.
