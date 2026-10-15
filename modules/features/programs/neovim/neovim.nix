{ inputs, self, ... }:
let
  packagesFor = pkgs: import ./config/packages.nix { inherit inputs pkgs; };
in
{
  perSystem =
    { pkgs, ... }:
    let
      packages = packagesFor pkgs;
    in
    {
      inherit packages;

      checks.neovim-options = import ./config/options-check.nix {
        inherit inputs self pkgs;
        configDir = toString ./.;
      };

      checks.neovim = pkgs.runCommand "neovim-variants" { } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        NVIM_TEST_VARIANT=minimal ${packages.neovim-minimal}/bin/nvim --headless -i NONE \
          -c 'lua dofile("${./config/check.lua}")' -c 'cquit 1'
        NVIM_TEST_VARIANT=full ${packages.neovim-full}/bin/nvim --headless -i NONE \
          -c 'lua dofile("${./config/check.lua}")' -c 'cquit 1'
        NVIM_TEST_VARIANT=full NVIM_CONFIG_DIR=${./.} ${packages.neovim-dev}/bin/nvim --headless -i NONE \
          -c 'lua dofile("${./config/check.lua}")' -c 'cquit 1'
        # A mutable checkout is reread on each launch, not frozen at build time.
        mkdir "$TMPDIR/config"
        for value in first second; do
          echo "vim.g.dev_probe = '$value'" > "$TMPDIR/config/init.lua"
          NVIM_CONFIG_DIR="$TMPDIR/config" ${packages.neovim-dev}/bin/nvim --headless -i NONE \
            -c "lua assert(vim.g.dev_probe == '$value'); vim.cmd('qa!')" -c 'cquit 1'
        done
        env -u NVIM_CONFIG_DIR ${packages.neovim-dev}/bin/nvim --headless -i NONE \
          -c 'qa!' > "$TMPDIR/missing-config.log" 2>&1 || true
        grep -q 'neovim-dev requires NVIM_CONFIG_DIR' "$TMPDIR/missing-config.log"
        touch "$out"
      '';

      checks.neovim-selection =
        let
          selected = host: host.config.home-manager.users.${host.config.my.user.name}.my.neovim.package;
          linuxPackages = self.packages.x86_64-linux;
        in
        assert
          (selected self.nixosConfigurations.saradomin).outPath == linuxPackages.neovim-minimal.outPath;
        assert
          (selected self.nixosConfigurations.saradomin-vm).outPath == linuxPackages.neovim-minimal.outPath;
        assert (selected self.nixosConfigurations.zaros).outPath == linuxPackages.neovim-full.outPath;
        assert
          (selected self.darwinConfigurations.macbook).outPath
          == self.packages.aarch64-darwin.neovim-full.outPath;
        assert packages.neovim.outPath == packages.neovim-full.outPath;
        pkgs.runCommand "neovim-host-selection" { } "touch $out";
    };

  flake.modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.neovim;
      packages =
        if cfg.variant == "dev" then
          import ./config/packages.nix {
            inherit inputs pkgs;
            inherit (cfg) devConfigDir;
          }
        else
          packagesFor pkgs;
    in
    {
      # Base and development both import this aspect through deferred modules.
      key = "nix-config/home-manager/neovim";

      options.my.neovim = {
        variant = lib.mkOption {
          type = lib.types.enum [
            "minimal"
            "full"
            "dev"
          ];
          default = "minimal";
          description = "Editor variant; development profiles default to full, dev reads a local Lua checkout.";
        };
        devConfigDir = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "/.+");
          default = null;
          example = "/home/felipe/repos/nix-config/modules/features/programs/neovim";
          description = "Absolute runtime config directory required for the dev variant. Use a string, not a Nix path, to keep edits outside the store.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = packages."neovim-${cfg.variant}";
          description = "Selected Neovim package; may be overridden for a custom editor.";
        };
      };

      config = {
        assertions = [
          {
            assertion = cfg.variant != "dev" || cfg.devConfigDir != null;
            message = "my.neovim.devConfigDir must be set when my.neovim.variant is dev.";
          }
        ];
        home.packages = [ cfg.package ];
      };
    };
}
