{ pkgs, lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
in
{
  vim.autocomplete.blink-cmp = {
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
}
