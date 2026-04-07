{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Core Languages ---
    go
    nodejs
    python3
    python3Packages.pip

    # --- Essential CLI Utilities ---
    ripgrep
    fd
    fzf
    jq
    bat
    lazygit
  ];
}
