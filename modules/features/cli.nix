{
  flake.homeModules.cli =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ripgrep
        fd
        jq
        bat
        fastfetch
        zip
        unzip
        p7zip-rar
        gnumake
        wakeonlan
        openssl
        herdr
      ];

      programs.tmux.enable = true;

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.eza = {
        enable = true;
        enableZshIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableZshIntegration = true;
      };
    };
}
