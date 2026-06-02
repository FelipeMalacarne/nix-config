let
  baseModule =
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
          kustomize
          kustomize-sops
        ];

        home.sessionVariables.KUBECONFIG = builtins.concatStringsSep ":" (
          map (name: "${homeDirectory}/.kube/configs/${name}.yaml") clusters
        );
      };
    };

  nixosModule =
    { config, ... }:
    let
      user = config.my.user.name;
      homeDirectory = config.users.users.${user}.home;
    in
    {
      imports = [ baseModule ];

      systemd.tmpfiles.rules = [
        "d ${homeDirectory}/.kube 0700 ${user} users -"
        "d ${homeDirectory}/.kube/configs 0700 ${user} users -"
      ];
    };
in
{
  flake.nixosModules.k8s = nixosModule;
  flake.darwinModules.k8s = baseModule;
}
