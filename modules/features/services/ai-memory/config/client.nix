{
  config,
  inputs,
  self,
  ...
}:
let
  registry = config.flake.modules;
  systemModule =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      options.my.ai.memory.client = clientOptions lib;

      config = {
        sops.secrets.ai-memory-token = (import ./credential.nix) // {
          owner = user;
        };
        home-manager.users.${user} = {
          imports = [ registry.homeManager.ai-memory-client ];
          my.ai.memory.client = config.my.ai.memory.client;
        };
        my.ai.memory.client.tokenFile = lib.mkDefault config.sops.secrets.ai-memory-token.path;
      };
    };
  clientOptions = lib: {
    serverUrl = lib.mkOption {
      type = lib.types.strMatching "https://[a-zA-Z0-9.-]+(:[0-9]+)?";
      description = "Private HTTPS base URL shared by MCP, hooks and recovery; no /mcp suffix.";
    };
    tokenFile = lib.mkOption {
      type = lib.types.strMatching "/.+";
      description = "Private runtime token path; only a symlink, never its contents, enters the Nix store.";
    };
  };
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.ai.memory.client;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.ai-memory;
      dataDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/ai-memory"
        else
          "${config.xdg.dataHome}/ai-memory";
      toml = (pkgs.formats.toml { }).generate "ai-memory-client.toml" {
        server_url = cfg.serverUrl;
        embedding_provider = "none";
        auth.bearer_token_file = "auth-token";
      };
      plugin = pkgs.runCommand "ai-memory-opencode2.ts" { nativeBuildInputs = [ package ]; } ''
        export HOME="$TMPDIR/home"
        export AI_MEMORY_DATA_DIR="$TMPDIR/data"
        mkdir -p "$HOME" "$AI_MEMORY_DATA_DIR"
        ai-memory install-hooks --agent opencode2 --capture-mode allowlist \
          --server-url ${lib.escapeShellArg cfg.serverUrl} \
          --apply --config-file "$out"
      '';
      skills = lib.genAttrs [
        "ai-memory-retrieval"
        "ai-memory-handoff"
        "ai-memory-durable-pages"
      ] (name: "${package.src}/crates/ai-memory-core/src/routing_skills/${name}");
    in
    {
      options.my.ai.memory.client = clientOptions lib;

      config = {
        assertions = [
          {
            assertion = config.programs.opencode.enable && config.programs.opencode.enableMcpIntegration;
            message = "ai-memory-client requires OpenCode with its MCP integration explicitly selected.";
          }
          {
            assertion = !(lib.hasPrefix "${builtins.storeDir}/" cfg.tokenFile);
            message = "ai-memory-client tokenFile must be a private runtime file, never a Nix store path.";
          }
        ];
        home.packages = [
          package
          pkgs.git
        ];
        # Never let managed launches rewrite Home Manager's agent configuration.
        home.sessionVariables.AI_MEMORY_RUN_AUTOWIRE = "false";
        home.activation.aiMemoryPrivateData =
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
            ''
              $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -d -m 700 ${lib.escapeShellArg dataDir}
            '';
        home.file.ai-memory-config = {
          target = "${dataDir}/config.toml";
          source = toml;
        };
        home.file.ai-memory-capture-mode = {
          target = "${dataDir}/capture-mode";
          text = "allowlist\n";
        };
        home.file.ai-memory-auth-token = {
          target = "${dataDir}/auth-token";
          source = config.lib.file.mkOutOfStoreSymlink cfg.tokenFile;
        };
        programs.mcp = {
          enable = true;
          servers.ai-memory = {
            command = lib.getExe package;
            args = [
              "--data-dir"
              dataDir
              "mcp-bridge"
              "--no-session-id"
              "--server-url"
              cfg.serverUrl
            ];
          };
        };
        # OpenCode's skills option probes directory paths during evaluation.
        # Declare the known directories directly so cross-platform evaluation
        # never has to realize the patched source derivation (IFD).
        xdg.configFile =
          lib.mapAttrs' (name: source: lib.nameValuePair "opencode/skills/${name}" { inherit source; }) skills
          // {
            "opencode/plugins/ai-memory-opencode2.ts".source = plugin;
          };
        programs.opencode.settings = {
          instructions = [ "${./workflow.md}" ];
          commands.memory-finish = {
            description = "Save a handoff and finish one explicitly identified ai-memory session";
            template = builtins.readFile ./memory-finish.md;
            subagent = false;
          };
        };
      };
    };
in
{
  flake.modules.homeManager.ai-memory-client = module;
  flake.modules.nixos.ai-memory-client = {
    imports = [
      registry.nixos.sops
      systemModule
    ];
  };
  flake.modules.darwin.ai-memory-client = {
    imports = [
      registry.darwin.sops
      systemModule
    ];
  };

  perSystem = { lib, pkgs, ... }: {
    checks.ai-memory-client = import ./test-client.nix {
      inherit lib pkgs module;
      inherit (inputs) home-manager;
    };
  };
}
