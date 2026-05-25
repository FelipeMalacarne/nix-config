{ ... }:
{
  vim.filetree.neo-tree = {
    enable = true;
    setupOpts = {
      close_if_last_window = true;
      sources = [ "filesystem" ];
      filesystem = {
        bind_to_cwd = false;
        follow_current_file.enabled = true;
        use_libuv_file_watcher = true;
        filtered_items = {
          visible = false;
          hide_dotfiles = false;
          hide_gitignored = false;
          hide_by_name = [
            ".git"
            "node_modules"
            "vendor"
          ];
        };
      };
      window = {
        width = 35;
        mappings = {
          "<space>" = "none";
          l = "open";
          h = "close_node";
        };
      };
      default_component_configs = {
        indent.with_expanders = true;
        icon = {
          folder_closed = "";
          folder_open = "";
          folder_empty = "󰜌";
        };
      };
    };
  };
}
