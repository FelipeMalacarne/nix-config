{
  flake.homeModules.btop = {
    programs.btop = {
      enable = true;
      settings = {
        theme_background = false;
        update_ms = 2000;
        rounded_corners = true;
      };
    };
  };
}
