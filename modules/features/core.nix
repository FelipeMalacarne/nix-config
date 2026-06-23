{ inputs, ... }:
{
  flake.nixosModules.core =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

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

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";

      users.users.${user} = {
        isNormalUser = true;
        hashedPassword = "$y$j9T$ZqyDJ7iWYtwx7.LZV2SVC.$rOHD5WSlDpCIf7mBvx1Y3SUr5fEatWAiEeKRYMZMKz1";
        extraGroups = [
          "wheel"
          "networkmanager"
        ];
      };

      home-manager.users.${user}.home = {
        username = user;
        homeDirectory = lib.mkDefault "/home/${user}";
        stateVersion = lib.mkDefault "24.11";
      };
    };
}
