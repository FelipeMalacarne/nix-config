{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- Core Languages ---
    go
    nodejs
    pnpm
    python3
    python3Packages.pip
    php85
    php85Packages.composer
    (laravel.override { php = php85; })

    # --- Essential CLI Utilities ---
    ripgrep
    fd
    fzf
    jq
    bat
    lazygit
  ];
}
