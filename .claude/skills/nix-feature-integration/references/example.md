# Cross-platform aspect with a feature-local check

Illustrative template, not a request to install `example-monitor`. Use current
`btop.nix` and the existing profiles as the production sources of truth; do not
create this duplicate alongside the existing btop feature.

## Discovered entrypoint

`modules/features/programs/example-monitor/example-monitor.nix`:

```nix
{ config, inputs, ... }:
let
  registry = config.flake.modules;
  forward = { config, ... }: {
    home-manager.users.${config.my.user.name}.imports = [
      registry.homeManager.example-monitor
    ];
  };
in
{
  flake.modules.homeManager.example-monitor = {
    programs.btop.enable = true;
    programs.btop.settings.update_ms = 2000;
  };
  flake.modules.nixos.example-monitor = forward;
  flake.modules.darwin.example-monitor = forward;

  perSystem = { pkgs, ... }: {
    checks.example-monitor = import ./config/test.nix {
      inherit pkgs;
      inherit (inputs) home-manager;
      module = registry.homeManager.example-monitor;
    };
  };
}
```

The outer `config` supplies the final registry; the inner `config` identifies
the primary user. This assumes the selecting host already supplies Home Manager
and `my.user.name`, as this repository's hosts do. The forwarding module does
not provision users or import profiles. If the feature is user-only, omit the
platform registrations and select it in the HM profile instead.

Select via `registry.<platform>.example-monitor` in a flake-parts profile, or
`self.modules.<platform>.example-monitor` in a plain host. Auto-discovery only
registers the feature; selection remains explicit.

## Excluded fixture

`modules/features/programs/example-monitor/config/test.nix`:

```nix
{ pkgs, home-manager, module }:
let
  evaluate = extraModules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home.username = "feature-check";
          home.homeDirectory = "/tmp/feature-check";
          home.stateVersion = "24.11";
        }
      ] ++ extraModules;
    }).config;
  absent = evaluate [ ];
  selected = evaluate [ module ];
in
assert !absent.programs.btop.enable;
assert selected.programs.btop.enable;
assert selected.programs.btop.settings.update_ms == 2000;
pkgs.runCommand "example-monitor-composition" { } "touch $out"
```

This checks the HM selection boundary only. Add platform fixture coverage when
introducing forwarding behavior, and real profile coverage for interactions.
Do not claim the fixture proves a binary launches or platform activation works.

Build a real check after replacing the example name:

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build --no-link "path:.#checks.${system}.example-monitor"
```

For a typed option, follow `wol.nix`: declare it in the owning feature, set the
machine's value in its host, and assert the resulting native service/config.
Do not generalize this tiny example into a custom feature registry or activation
framework; flake-parts and native module imports already provide composition.
