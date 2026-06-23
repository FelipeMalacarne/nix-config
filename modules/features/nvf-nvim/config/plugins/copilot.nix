{ ... }:
{
  vim.assistant.copilot = {
    enable = true;
    setupOpts = {
      suggestion.enabled = false;
      panel.enabled = false;
    };
  };
}
