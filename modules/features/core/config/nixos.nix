{ inputs, self, ... }:
{
  flake.nixosModules.core =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.home-manager-policy
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
        substituters = [ "https://nvf.cachix.org" ];
        trusted-public-keys = [ "nvf.cachix.org-1:GMQWiUhZ6ux9D5CvFFMwnc2nFrUHTeGaXRlVBXo+naI=" ];
      };

      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.permittedInsecurePackages = [
        "electron-39.8.10"
      ];
      programs.nix-ld.enable = true;
      nix.registry.nixpkgs.flake = inputs.nixpkgs;

      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

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
        imports = [ self.homeModules.identity ];
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
