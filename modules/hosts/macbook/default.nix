{ inputs, self, ... }:
{
  flake.darwinConfigurations.macbook = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [ self.darwinModules.macbook ];
  };
}
