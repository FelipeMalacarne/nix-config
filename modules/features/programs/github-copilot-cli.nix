{
  flake.modules.homeManager.github-copilot-cli = { pkgs, ... }: {
    home.packages = [ pkgs.github-copilot-cli ];
  };
}
