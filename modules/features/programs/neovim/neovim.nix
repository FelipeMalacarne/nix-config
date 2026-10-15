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
    {
      # Base and development both import this aspect through deferred modules.
      key = "nix-config/home-manager/neovim";

      options.my.neovim.package = lib.mkOption {
        type = lib.types.package;
        default = (packagesFor pkgs).neovim-minimal;
        description = "Neovim variant to install; minimal by default, full in the development profile.";
      };

      config.home.packages = [ config.my.neovim.package ];
    };
}
