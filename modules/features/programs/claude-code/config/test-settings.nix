{
  lib,
  pkgs,
  home-manager,
  module,
}:
let
  evaluate =
    extra:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        module
        {
          home.username = "claude-settings-check";
          home.homeDirectory = "/tmp/claude-settings-check";
          home.stateVersion = "24.11";
        }
        extra
      ];
    }).config;
  default = evaluate { };
  custom = evaluate {
    programs.claude-code = {
      configDir = "/tmp/claude-settings-check/custom-claude";
      settings.enabledPlugins."fixture@example" = true;
      mcpServers.disabled-fixture = {
        command = "fixture";
        enabled = false;
      };
    };
  };
  defaultFile = default.home.file."${default.programs.claude-code.configDir}/settings.json";
  customFile = custom.home.file."${custom.programs.claude-code.configDir}/settings.json";
  legacyFiles = pkgs.linkFarm "home-manager-files" [
    {
      name = ".claude/settings.json";
      path = defaultFile.source;
    }
  ];
in
assert defaultFile.target == ".claude/settings.nix.json";
assert customFile.target == "custom-claude/settings.nix.json";
assert !(default.programs.opencode.enable or false);
assert default.home.activation.claudeSettings.before == [ "linkGeneration" ];
assert default.home.activation.claudeSettings.after == [ "writeBoundary" ];
assert default.home.activation.claudeSettingsCheck.before == [ "writeBoundary" ];
assert lib.hasInfix "--check" default.home.activation.claudeSettingsCheck.data;
pkgs.runCommand "claude-writable-settings" { nativeBuildInputs = [ pkgs.jq ]; } ''
  export PYTHONDONTWRITEBYTECODE=1
  ${pkgs.python3}/bin/python3 ${./.}/test_settings.py
  test -f ${default.home-files}/.claude/settings.nix.json
  test ! -e ${default.home-files}/.claude/settings.json
  test -f ${custom.home-files}/custom-claude/settings.nix.json
  test ! -e ${custom.home-files}/custom-claude/settings.json
  jq -e '.model == "claude-opus-5-5" and .enabledPlugins["gopls-lsp@claude-plugins-official"] == true' \
    ${defaultFile.source} > /dev/null
  jq -e '.enabledPlugins["fixture@example"] == true and
    (.disabledMcpjsonServers | index("disabled-fixture") != null)' \
    ${customFile.source} > /dev/null

  # Exercise the real CLI against the two-hop Home Manager symlink layout.
  settings="$TMPDIR/home/.claude/settings.json"
  baseline="$TMPDIR/home/.claude/settings.nix.json"
  mkdir -p "$(dirname "$settings")"
  ln -s ${legacyFiles}/.claude/settings.json "$settings"
  ${pkgs.python3}/bin/python3 -B ${./settings.py} \
    ${customFile.source} "$settings" "$baseline" ${builtins.storeDir} --check
  test -L "$settings"
  ${pkgs.python3}/bin/python3 -B ${./settings.py} \
    ${customFile.source} "$settings" "$baseline" ${builtins.storeDir}
  test ! -L "$settings"
  jq -e '.enabledPlugins["fixture@example"] == true' "$settings" > /dev/null
  ln -s ${custom.home-files}/custom-claude/settings.nix.json "$baseline"
  jq '.modelSettings.fixture.effortLevel = "high" |
    .enabledPlugins["fixture@example"] = false' "$settings" > "$settings.tmp"
  mv "$settings.tmp" "$settings"
  ${pkgs.python3}/bin/python3 -B ${./settings.py} \
    ${defaultFile.source} "$settings" "$baseline" ${builtins.storeDir}
  jq -e '.modelSettings.fixture.effortLevel == "high" and
    .enabledPlugins["fixture@example"] == false and
    (has("disabledMcpjsonServers") | not)' "$settings" > /dev/null
  touch "$out"
''
