{ pkgs, lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
in
{
  vim = {
    startPlugins = with pkgs.vimPlugins; [
      dressing-nvim
      nvim-ts-context-commentstring
    ];

    telescope = {
      enable = true;
      mappings = {
        findFiles = "<leader>ff";
        liveGrep = "<leader>fg";
        buffers = "<leader>fb";
        helpTags = "<leader>fh";
        open = null;
        resume = null;
        gitFiles = null;
        gitCommits = null;
        gitBufferCommits = null;
        gitBranches = null;
        gitStatus = null;
        gitStash = null;
        lspDocumentSymbols = "<leader>fs";
        lspWorkspaceSymbols = null;
        lspReferences = null;
        lspImplementations = null;
        lspDefinitions = null;
        lspTypeDefinitions = null;
        diagnostics = "<leader>fd";
        treesitter = null;
        findProjects = null;
      };
      extensions = [
        {
          name = "fzf";
          packages = [ pkgs.vimPlugins.telescope-fzf-native-nvim ];
        }
      ];
      setupOpts.defaults = {
        prompt_prefix = "  ";
        selection_caret = " ";
        path_display = [ "truncate" ];
        sorting_strategy = "ascending";
        layout_config = {
          horizontal = {
            prompt_position = "top";
            preview_width = 0.55;
          };
          vertical.mirror = false;
          width = 0.87;
          height = 0.80;
        };
        mappings.i = {
          "<C-j>" = "move_selection_next";
          "<C-k>" = "move_selection_previous";
          "<C-q>" = "send_to_qflist";
          "<esc>" = "close";
        };
      };
    };

    filetree.neo-tree = {
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

    autocomplete.blink-cmp = {
      enable = true;
      friendly-snippets.enable = true;
      mappings = {
        complete = null;
        confirm = null;
        next = null;
        previous = null;
        close = null;
        scrollDocsUp = null;
        scrollDocsDown = null;
      };
      sourcePlugins.copilot = {
        enable = true;
        package = pkgs.vimPlugins.blink-copilot;
        module = "blink-copilot";
      };
      setupOpts = {
        keymap = {
          preset = "default";
          "<Tab>" = [
            "select_next"
            "snippet_forward"
            "fallback"
          ];
          "<S-Tab>" = [
            "select_prev"
            "snippet_backward"
            "fallback"
          ];
          "<CR>" = [
            "accept"
            "fallback"
          ];
          "<C-Space>" = [
            "show"
            "show_documentation"
            "hide_documentation"
          ];
          "<C-e>" = [ "hide" ];
          "<C-b>" = [
            "scroll_documentation_up"
            "fallback"
          ];
          "<C-f>" = [
            "scroll_documentation_down"
            "fallback"
          ];
        };
        appearance = {
          use_nvim_cmp_as_default = false;
          nerd_font_variant = "mono";
        };
        sources = {
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "copilot"
          ];
          providers = {
            lsp.score_offset = 5;
            copilot = {
              name = "copilot";
              module = "blink-copilot";
              score_offset = 100;
              async = true;
            };
          };
        };
        completion = {
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };
          ghost_text.enabled = true;
          menu.draw.columns = [
            [
              "label"
              "label_description"
              (mkLuaInline "gap = 1")
            ]
            [
              "kind_icon"
              "kind"
            ]
          ];
        };
        signature.enabled = true;
      };
    };

    assistant.copilot = {
      enable = true;
      setupOpts = {
        suggestion.enabled = false;
        panel.enabled = false;
      };
    };

    lazy.plugins."CopilotChat.nvim" = {
      package = pkgs.vimPlugins.CopilotChat-nvim;
      cmd = [
        "CopilotChat"
        "CopilotChatCommit"
      ];
      before = ''
        require("lz.n").trigger_load("copilot-lua")
      '';
      setupModule = "CopilotChat";
      setupOpts.window = {
        layout = "float";
        border = "rounded";
        width = 0.8;
        height = 0.8;
      };
      keys = [
        {
          mode = [
            "n"
            "v"
          ];
          key = "<leader>ap";
          action = ''function() require("CopilotChat").select_prompt() end'';
          lua = true;
          desc = "Copilot quick actions";
        }
        {
          mode = "n";
          key = "<leader>ac";
          action = ''
            function()
              require("CopilotChat").ask(
                "Write a commit message for the staged changes. Follow conventional commits format. Only output the commit message, no explanation.",
                { context = "git:staged" }
              )
            end
          '';
          lua = true;
          desc = "Copilot commit message";
        }
        {
          mode = [
            "n"
            "v"
          ];
          key = "<leader>aa";
          action = ''function() require("CopilotChat").toggle() end'';
          lua = true;
          desc = "Copilot toggle chat";
        }
      ];
    };

    git.gitsigns = {
      enable = true;
      mappings = {
        nextHunk = "]h";
        previousHunk = "[h";
        stageHunk = "<leader>hs";
        resetHunk = "<leader>hr";
        undoStageHunk = "<leader>hu";
        stageBuffer = "<leader>hS";
        resetBuffer = "<leader>hR";
        previewHunk = "<leader>hp";
        blameLine = "<leader>hb";
        diffThis = "<leader>hd";
        diffProject = "<leader>hD";
        toggleBlame = null;
        toggleDeleted = null;
      };
      setupOpts.signs = {
        add.text = "▎";
        change.text = "▎";
        delete.text = "";
        topdelete.text = "";
        changedelete.text = "▎";
        untracked.text = "▎";
      };
    };

    binds.whichKey = {
      enable = true;
      register = {
        "<leader>f" = "Find / Telescope";
        "<leader>g" = "Git";
        "<leader>h" = "Git hunks";
        "<leader>c" = "Code";
        "<leader>b" = "Buffer";
        "<leader>d" = "Diagnostics";
        "<leader>a" = "AI";
      };
      setupOpts.preset = "modern";
    };

    utility.snacks-nvim = {
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
    };

    autopairs.nvim-autopairs = {
      enable = true;
      setupOpts = {
        check_ts = true;
        ts_config = {
          lua = [ "string" ];
          javascript = [ "template_string" ];
        };
        disable_filetype = [ "TelescopePrompt" ];
      };
    };

    mini = {
      ai.enable = true;
      surround = {
        enable = true;
        setupOpts.mappings = {
          add = "gsa";
          delete = "gsd";
          find = "gsf";
          find_left = "gsF";
          highlight = "gsh";
          replace = "gsr";
          update_n_lines = "gsn";
        };
      };
      comment = {
        enable = true;
        setupOpts.options.custom_commentstring = mkLuaInline ''
          function()
            return require("ts_context_commentstring.internal").calculate_commentstring()
              or vim.bo.commentstring
          end
        '';
      };
      jump2d.enable = true;
    };

    visuals.indent-blankline = {
      enable = true;
      setupOpts = {
        indent.char = "│";
        scope.enabled = false;
        exclude.filetypes = [
          "help"
          "lazy"
          "neo-tree"
          "Trouble"
          "toggleterm"
        ];
      };
    };

    ui.colorizer = {
      enable = true;
      setupOpts.user_default_options.tailwind = true;
    };
  };
}
