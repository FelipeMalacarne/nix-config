{
  lib,
  pkgs,
  home-manager,
  module,
  opencode,
}:
let
  # Deliberately give the mock package a GUI mainProgram. The integration must
  # still use the named CLI and preserve custom package paths.
  package = (pkgs.writeShellScriptBin "filmcraft-cli" "exit 0").overrideAttrs (_: {
    meta.mainProgram = "filmcraft";
  });
  replacement = pkgs.writeShellScriptBin "filmcraft-cli" "exit 1";
  evaluate =
    osConfig:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = lib.optionalAttrs (osConfig != null) { inherit osConfig; };
      modules = [
        module
        {
          home.username = "craft-check";
          home.homeDirectory = "/tmp/craft-check";
          home.stateVersion = "24.11";
        }
      ];
    }).config;
  standalone = evaluate null;
  absent = evaluate { };
  disabled = evaluate {
    my.artcraft.filmcraft = {
      enable = false;
      inherit package;
    };
  };
  film = evaluate {
    my.artcraft = {
      filmcraft = {
        enable = true;
        inherit package;
      };
      photocraft = {
        enable = false;
        inherit package;
      };
    };
  };
  overridden = evaluate {
    my.artcraft.filmcraft = {
      enable = true;
      package = replacement;
    };
  };
  multiple = evaluate {
    my.artcraft = {
      filmcraft = {
        enable = true;
        inherit package;
      };
      photocraft = {
        enable = true;
        inherit package;
      };
    };
  };
  servers = cfg: builtins.attrNames cfg.programs.mcp.servers;
  empty =
    cfg:
    servers cfg == [ "playwright" ]
    && !(cfg.programs.opencode.settings ? agent)
    && !(cfg.programs.opencode.skills ? artcraft-editing);
  json = cfg: cfg.xdg.configFile."opencode/opencode.json".source;
in
assert standalone.programs.opencode.package == opencode;
assert !(lib.any (package: lib.getName package == "opencode-desktop") standalone.home.packages);
assert lib.versions.major (lib.getVersion opencode) == "2";
assert lib.assertMsg (lib.all empty [
  standalone
  absent
  disabled
]) "OpenCode must not require ArtCraft or install editing integration without a selection";
assert lib.assertMsg (
  servers film == [
    "craft-filmcraft"
    "playwright"
  ]
) "Only selected apps should be registered alongside existing MCP servers";
assert lib.assertMsg (
  servers multiple == [
    "craft-filmcraft"
    "craft-photocraft"
    "playwright"
  ]
) "Craft MCP selection must work independently for multiple apps";
assert lib.assertMsg (
  film.programs.mcp.servers.craft-filmcraft.command == lib.getExe' package "filmcraft-cli"
  &&
    overridden.programs.mcp.servers.craft-filmcraft.command == lib.getExe' replacement "filmcraft-cli"
  && film.programs.mcp.servers.craft-filmcraft.args == [ "mcp" ]
  && overridden.programs.mcp.servers.craft-filmcraft.args == [ "mcp" ]
  && multiple.programs.mcp.servers.craft-filmcraft.args == [ "mcp" ]
  && multiple.programs.mcp.servers.craft-photocraft.args == [ "mcp" ]
) "MCP must run the named CLI from the host's actual package, including overrides";
assert lib.assertMsg (
  film.programs.opencode.settings.tools."craft-*" == false
  && film.programs.opencode.settings.agent.craft-editor.tools."craft-*" == true
  && film.programs.opencode.settings.agent.craft-editor.mode == "subagent"
  && !(film.programs.opencode.settings.agent.craft-editor ? model)
  && film.programs.opencode.skills ? artcraft-editing
) "Editing tools must be scoped to the editor without forcing a model";
pkgs.runCommand "opencode-craft"
  {
    nativeBuildInputs = [
      pkgs.jq
      opencode
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_STATE_HOME="$TMPDIR/state"
    export OPENCODE_DISABLE_MODELS_FETCH=true
    export OPENCODE_DISABLE_AUTOUPDATE=true
    export OPENCODE_CONFIG_PROJECT_DISABLE=true
    export OPENCODE_CONFIG=${json film}
    mkdir -p "$HOME" "$XDG_CONFIG_HOME/opencode"
    cp ${pkgs.writeText "opencode-service-prod.json" ''{"disabled":true}''} \
      "$XDG_CONFIG_HOME/opencode/service-prod.json"
    timeout 60s opencode debug config > "$TMPDIR/config-entries.json"
    jq -e --arg path "$OPENCODE_CONFIG" '
      [.[] | select(.type == "document" and .path == $path) | .info] as $docs |
      ($docs | length) == 1 and ($docs[0] |
        .lsp == true and
        .mcp.servers["craft-filmcraft"].disabled == false)
    ' "$TMPDIR/config-entries.json" > /dev/null
    jq -e --arg cli ${lib.escapeShellArg (lib.getExe' package "filmcraft-cli")} '
      .mcp["craft-filmcraft"].command == [$cli, "mcp"] and
      .mcp["craft-filmcraft"].type == "local" and
      .mcp["craft-filmcraft"].enabled == true and
      (.mcp | keys) == ["craft-filmcraft", "playwright"] and
      .tools["craft-*"] == false and
      .agent["craft-editor"].tools["craft-*"] == true and
      .agent["craft-editor"].mode == "subagent" and
      (.agent["craft-editor"].prompt | contains("artcraft-editing"))
    ' ${json film} > /dev/null
    jq -e --arg cli ${lib.escapeShellArg (lib.getExe' replacement "filmcraft-cli")} '
      .mcp["craft-filmcraft"].command == [$cli, "mcp"]
    ' ${json overridden} > /dev/null
    jq -e '(.mcp | keys) == ["playwright"] and (has("agent") | not)' ${json absent} > /dev/null
    test -f ${film.programs.opencode.skills.artcraft-editing}/SKILL.md
    touch $out
  ''
