{ pkgs, ... }:

{
  imports = [
    ./nvidia.nix
    ./fonts.nix
    # ./example.nix - add your modules here
  ];

  programs.git = {
    enable = true;
    config = {
        init = {
            defaultBranch = "main";
        };

        url = {
            "https://github.com/" = {
            insteadOf = [
                "gh:"
                "github:"
                ];
            };
        };
        user.name = "FelipeMalacarne";
        user.email = "felipemalacarne012@gmail.com";
    };
  };

  environment.systemPackages = [
    pkgs.bolt-launcher
    # pkgs.vscode
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];
}
