{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.opencode = inputs.wrapper-modules.wrappers.opencode.wrap {
      inherit pkgs;
    };
  };
}
