{ ... }:
{
  vim.filetree.neo-tree = {
    enable = true;
    setupOpts = {
      close_if_last_window = true;

      git_status_async = true;
      # sources = [ "filesystem" ];
      filesystem = {
        follow_current_file.enabled = true;
        #   bind_to_cwd = false;
        #   use_libuv_file_watcher = true;
        #   filtered_items = {
        #     visible = false;
        #     hide_dotfiles = false;
        #     hide_gitignored = true;
        #     hide_by_name = [
        #       ".git"
        #       "node_modules"
        #       "vendor"
        #     ];
        #   };
      };
      window = {
        position = "float";
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
