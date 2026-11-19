{ inputs, ... }:
{
  flake.modules.homeManager.orca =
    { pkgs, ... }:
    {
      home.packages = [ inputs.orca.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    };
}
