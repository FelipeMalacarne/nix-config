{ pkgs, inputs, ... }:

{
  imports = [
    ./nvidia.nix
    ./fonts.nix
    # ./example.nix - add your modules here
  ];

  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  programs = {
    direnv.enable = true;

    git = {
      enable = true;
      config = {
        init = { defaultBranch = "main"; };

        url = { "https://github.com/" = { insteadOf = [ "gh:" "github:" ]; }; };
        user.name = "FelipeMalacarne";
        user.email = "felipemalacarne012@gmail.com";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    pkgs.bolt-launcher
    inputs.zen-browser.packages."${system}".default
    # pkgs.vscode
    # pkgs.userPkgs.vscode - your personal nixpkgs version
  ];
}
