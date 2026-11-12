# Cross-platform aspect with a feature-local check

Illustrative template, not a request to install `example-monitor`. Use current
`btop.nix` and the existing profiles as the production sources of truth; do not
create this duplicate alongside the existing btop feature.

## Discovered entrypoint

`modules/features/programs/example-monitor.nix`:

```nix
{ config, ... }:
let
  registry = config.flake.modules;
  forward = {
    home-manager.sharedModules = [ registry.homeManager.example-monitor ];
  };
in
{
  flake.modules.homeManager.example-monitor = {
    programs.btop.enable = true;
    programs.btop.settings.update_ms = 2000;
  };
  flake.modules.nixos.example-monitor = forward;
  flake.modules.darwin.example-monitor = forward;

  perSystem =
    { evalHome, mkAssertCheck, ... }:
    let
      absent = evalHome [ ];
      selected = evalHome [ registry.homeManager.example-monitor ];
    in
    {
      checks.example-monitor = mkAssertCheck "example-monitor" [
        {
          assertion = !absent.programs.btop.enable;
          message = "btop must not be enabled without importing the aspect.";
        }
        {
          assertion = selected.programs.btop.enable && selected.programs.btop.settings.update_ms == 2000;
          message = "Importing example-monitor must enable btop with its refresh rate.";
        }
      ];
    };
}
```

The outer `config` supplies the final registry. `home-manager.sharedModules`
reaches the host's Home Manager user without needing its name, and module keys
make a repeated forward harmless. This assumes the selecting host already
supplies Home Manager through `base`, as this repository's hosts do. If the
feature is user-only, omit the platform registrations and select it in the HM
profile instead.

Select via `registry.<platform>.example-monitor` in a flake-parts profile, or
`self.modules.<platform>.example-monitor` in a plain host. Auto-discovery only
registers the feature; selection remains explicit.

`evalHome` evaluates Home Manager modules for a throwaway user and
`mkAssertCheck` reports every failed message at once; both come from
`modules/checks/lib.nix`. This checks the HM selection boundary only. Add a
`fixtures.mkFeatureConfig` check when introducing platform behavior, and real
profile coverage for interactions. Do not claim the check proves a binary
launches or platform activation works. When a feature grows helpers or data,
move it to `example-monitor/example-monitor.nix` with a `config/` directory.

Build a real check after replacing the example name:

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build --no-link "path:.#checks.${system}.example-monitor"
```

For a typed option, follow `wol.nix`: declare it in the owning feature, set the
machine's value in its host, and assert the resulting native service/config.
Do not generalize this tiny example into a custom feature registry or activation
framework; flake-parts and native module imports already provide composition.
