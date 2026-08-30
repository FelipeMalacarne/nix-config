{ lib, ... }:
let
  topologyModule =
    { config, ... }:
    let
      outputs = config.my.displayTopology.outputs;
      outputList = lib.attrValues outputs;
      roles = map (output: output.role) outputList;
      identifiers = lib.concatMap (output: [
        output.waylandDescription
        output.xrandrOutput
      ]) outputList;
      workspaces = lib.concatMap (output: output.workspaces) outputList;
    in
    {
      options.my.displayTopology.outputs = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              role = lib.mkOption {
                type = lib.types.enum [
                  "primary"
                  "secondary"
                ];
              };
              waylandDescription = lib.mkOption { type = lib.types.str; };
              xrandrOutput = lib.mkOption { type = lib.types.str; };
              mode = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    width = lib.mkOption { type = lib.types.ints.positive; };
                    height = lib.mkOption { type = lib.types.ints.positive; };
                    refresh = lib.mkOption { type = lib.types.numbers.positive; };
                  };
                };
              };
              position = lib.mkOption {
                type = lib.types.submodule {
                  options = {
                    x = lib.mkOption { type = lib.types.int; };
                    y = lib.mkOption { type = lib.types.int; };
                  };
                };
              };
              rotation = lib.mkOption {
                type = lib.types.enum [
                  0
                  90
                  180
                  270
                ];
                default = 0;
              };
              scale = lib.mkOption {
                type = lib.types.numbers.positive;
                default = 1;
              };
              workspaces = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
            };
          }
        );
      };
      config.assertions = [
        {
          assertion = outputList == [ ] || lib.length (lib.filter (role: role == "primary") roles) == 1;
          message = "my.displayTopology.outputs must define exactly one primary output";
        }
        {
          assertion = lib.length (lib.unique identifiers) == lib.length identifiers;
          message = "my.displayTopology output identifiers must be unique";
        }
        {
          assertion = lib.length (lib.unique workspaces) == lib.length workspaces;
          message = "my.displayTopology workspaces must be unique";
        }
        {
          assertion = lib.all (output: output.scale == 1) outputList;
          message = "my.displayTopology scale must be 1 for i3/XRandR-compatible topology";
        }
      ];
    };
in
{
  flake.nixosModules.displayTopology = topologyModule;
  flake.homeModules.displayTopology = topologyModule;
}
