{ pkgs, ... }:

{
  imports = [
    ../../modules/darwin/yabai.nix
    ../../modules/darwin/skhd.nix
  ];

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  nix.settings.experimental-features = "nix-command flakes";

  nixpkgs.config.allowUnfree = true;

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 4;

  users.users.felipeautentique = {
    name = "felipeautentique";
    home = "/Users/felipeautentique";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.felipeautentique = {
    imports = [
      ../../modules/home/common/default.nix
      ../../modules/home/darwin/ssh.nix
      ../../modules/home/desktop/alacritty.nix
    ];
    home.username = "felipeautentique";
    home.homeDirectory = "/Users/felipeautentique";
  };
}
