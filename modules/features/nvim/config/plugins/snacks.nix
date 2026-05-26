{ ... }:
{
  vim.utility.snacks-nvim = {
    enable = true;
    setupOpts.dashboard = {
      enabled = true;
      preset = {
        header = ''
           _   ___     _____ __  __
          | \ | \ \   / /_ _|  \/  |
          |  \| |\ \ / / | || |\/| |
          | |\  | \ V /  | || |  | |
          |_| \_|  \_/  |___|_|  |_|
        '';
        keys = [
          {
            icon = " ";
            key = "n";
            desc = "New File";
            action = ":ene | startinsert";
          }
          {
            icon = " ";
            key = "f";
            desc = "Find File";
            action = ":Telescope find_files";
          }
          {
            icon = " ";
            key = "g";
            desc = "Live Grep";
            action = ":Telescope live_grep";
          }
          {
            icon = " ";
            key = "q";
            desc = "Quit";
            action = ":qa";
          }
        ];
      };
      sections = [
        { section = "header"; }
        {
          section = "keys";
          gap = 1;
          padding = 1;
        }
        { section = "startup"; }
      ];
    };
    setupOpts.zen.enabled = true;
    setupOpts.zen.toggles.dim = false;
    setupOpts.styles.zen.backdrop = {
      transparent = false;
      blend = 99;
    };
  };
}
