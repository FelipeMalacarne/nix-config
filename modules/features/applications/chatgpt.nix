{
  flake.modules.homeManager.chatgpt = { pkgs, ... }: {
    home.packages = [ pkgs.chatgpt ];
  };
}
