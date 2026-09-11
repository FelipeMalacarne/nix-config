{
  flake.homeModules.ghostty =
    { lib, pkgs, ... }:
    {
      home.sessionVariables.TERMINAL = "ghostty";

      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        enableZshIntegration = true;

        settings = {
          background-opacity = lib.mkForce 0.95;
          window-decoration = "none";
        };
      };
    };
}
