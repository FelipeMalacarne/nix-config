{
  inputs,
  self,
  pkgs,
  configDir,
}:
let
  inherit (pkgs) lib;
  packages = self.packages.${pkgs.stdenv.hostPlatform.system};
  mkHome =
    settings:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        self.modules.homeManager.neovim
        {
          home.username = "neovim-test";
          home.homeDirectory = "/home/neovim-test";
          home.stateVersion = "24.11";
          my.neovim = settings;
        }
      ];
    }).config;
  minimal = mkHome { };
  full = mkHome { variant = "full"; };
  dev = mkHome {
    variant = "dev";
    devConfigDir = configDir;
  };
  missingDir = builtins.tryEval (mkHome { variant = "dev"; }).my.neovim.variant;
  invalidVariant = builtins.tryEval (mkHome { variant = "unknown"; }).my.neovim.variant;
  relativeDir =
    builtins.tryEval
      (mkHome {
        variant = "dev";
        devConfigDir = "relative/path";
      }).my.neovim.devConfigDir;
  custom = mkHome { package = pkgs.neovim-unwrapped; };
in
assert minimal.my.neovim.variant == "minimal";
assert minimal.my.neovim.package.outPath == packages.neovim-minimal.outPath;
assert full.my.neovim.package.outPath == packages.neovim-full.outPath;
assert custom.my.neovim.package.outPath == pkgs.neovim-unwrapped.outPath;
assert lib.all (a: a.assertion) dev.assertions;
assert !missingDir.success;
assert !invalidVariant.success;
assert !relativeDir.success;
assert !(dev.home.sessionVariables ? NVIM_CONFIG_DIR);
assert builtins.elem dev.my.neovim.package dev.home.packages;
pkgs.runCommand "neovim-options" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  # The Home Manager option is baked into the wrapper, not taken from the shell.
  NVIM_CONFIG_DIR=/nonexistent NVIM_TEST_VARIANT=full \
    ${dev.my.neovim.package}/bin/nvim --headless -i NONE \
      -c 'lua dofile("${./check.lua}")' -c 'cquit 1'
  touch "$out"
''
