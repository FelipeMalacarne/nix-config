{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Core Languages ---
    go
    nodejs
    python3
    python3Packages.pip
    php85
    php85Packages.composer

    # --- Essential CLI Utilities ---
    ripgrep
    fd
    fzf
    jq
    bat
    lazygit
  ];
}
