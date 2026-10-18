{ config, inputs, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.core =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        registry.nixos.home-manager-policy
      ];

      i18n.defaultLocale = "en_US.UTF-8";
      time.timeZone = "America/Sao_Paulo";

      services.xserver.xkb = {
        layout = "us";
        variant = "intl";
      };

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      nixpkgs.config.allowUnfree = true;
      programs.nix-ld.enable = true;
      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      boot.tmp.cleanOnBoot = true;

      users.users.${user} = {
        isNormalUser = true;
        home =
          if config.my.user.homeDirectory == null then "/home/${user}" else config.my.user.homeDirectory;
        hashedPassword = "$y$j9T$ZqyDJ7iWYtwx7.LZV2SVC.$rOHD5WSlDpCIf7mBvx1Y3SUr5fEatWAiEeKRYMZMKz1";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };

      home-manager.users.${user} = {
        imports = [ registry.homeManager.identity ];
        my.user = config.my.user;
        home = {
          username = user;
          homeDirectory = lib.mkDefault (
            if config.my.user.homeDirectory == null then "/home/${user}" else config.my.user.homeDirectory
          );
          stateVersion = lib.mkDefault "24.11";
        };
      };
    };
}
