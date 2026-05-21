let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.home-manager.users.${user}.home.homeDirectory;
      clusters = [
        "zamorak"
        "saradomin"
      ];
    in
    {
      sops.secrets = builtins.listToAttrs (
        map (name: {
          name = "${name}-kubeconfig";
          value = {
            owner = user;
            path = "${homeDirectory}/.kube/configs/${name}.yaml";
            mode = "0600";
          };
        }) clusters
      );

      home-manager.users.${user} = {
        home.packages = with pkgs; [
          kubectl
          kubectx
          kubernetes-helm
          k9s
          yq-go
        ];

        home.sessionVariables.KUBECONFIG = builtins.concatStringsSep ":" (
          map (name: "${homeDirectory}/.kube/configs/${name}.yaml") clusters
        );
      };
    };
in
{
  flake.nixosModules.k8s = module;
  flake.darwinModules.k8s = module;
}
