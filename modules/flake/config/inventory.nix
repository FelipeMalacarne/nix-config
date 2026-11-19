# Report what a NixOS or nix-darwin configuration installs, grouped by the
# aspect that asked for it. Read from the evaluated module graph and option
# definitions, so it shows what the host gets rather than what files say.
#
#   make inventory HOST=zaros
system:
let
  inherit (builtins)
    attrNames
    concatMap
    concatStringsSep
    elemAt
    filter
    head
    listToAttrs
    match
    sort
    ;

  aspectOf = key: match ".*#modules\\.[A-Za-z]+\\.([^:]+)" key;
  hostFileOf = file: match ".*-source/(hosts/[^ ]*)" file;

  # The module graph collapsed to registered aspects; upstream modules and
  # anonymous wrappers are skipped but their imports are kept.
  aspects =
    node:
    let
      aspect = aspectOf node.key;
      children = concatMap aspects node.imports;
    in
    if aspect != null && match ".*:anon.*" node.key == null then
      [
        {
          name = head aspect;
          inherit children;
        }
      ]
    else
      children;

  renderTree =
    indent: nodes:
    concatMap (node: [ "${indent}${node.name}" ] ++ renderTree "${indent}  " node.children) nodes;

  # A definition's owner: the aspect or host file that wrote it. Upstream
  # module defaults have no owner and are left out.
  ownerOf =
    file:
    let
      aspect = match ".*via option flake\\.modules\\.[A-Za-z]+\\.([^ ]+)" file;
      hostFile = hostFileOf file;
    in
    if aspect != null then
      head aspect
    else if hostFile != null then
      head hostFile
    else
      null;

  groupByOwner =
    definitions:
    let
      owned = filter (definition: definition.owner != null) (
        map (definition: definition // { owner = ownerOf definition.file; }) definitions
      );
      owners = attrNames (
        listToAttrs (
          map (definition: {
            name = definition.owner;
            value = null;
          }) owned
        )
      );
    in
    map (owner: {
      inherit owner;
      items = sort builtins.lessThan (
        concatMap (definition: definition.value) (filter (definition: definition.owner == owner) owned)
      );
    }) owners;

  renderGroups =
    groups:
    map (group: "  ${group.owner}: ${concatStringsSep " " group.items}") (
      filter (group: group.items != [ ]) groups
    );

  packageGroups =
    option:
    groupByOwner (
      map (definition: {
        inherit (definition) file;
        value = map (package: package.pname or package.name or "?") definition.value;
      }) option.definitionsWithLocations
    );

  # Upstream `programs.*` and `services.*` modules switched on by this repo.
  enabledGroups =
    options: prefix:
    groupByOwner (
      concatMap (
        name:
        let
          enable = options.${name}.enable or null;
        in
        if enable != null && enable ? definitionsWithLocations then
          map (definition: {
            inherit (definition) file;
            value = if definition.value == true then [ "${prefix}.${name}" ] else [ ];
          }) enable.definitionsWithLocations
        else
          [ ]
      ) (attrNames options)
    );

  section =
    title: lines:
    if lines == [ ] then
      [ ]
    else
      [
        ""
        title
      ]
      ++ lines;

  report =
    title: configuration: enabled:
    [
      "== ${title}"
      ""
      "aspects:"
    ]
    ++ renderTree "  " (concatMap aspects configuration.graph)
    ++ section "packages:" (renderGroups (packageGroups configuration.packages))
    ++ section "enabled modules:" (renderGroups enabled);

  inherit (system) options;
  user = system.config.my.user.name;
  home = options.home-manager.users.valueMeta.attrs.${user}.configuration;
in
concatStringsSep "\n" (
  report "${system.config.networking.hostName} system" {
    inherit (system) graph;
    packages = options.environment.systemPackages;
  } (enabledGroups options.programs "programs" ++ enabledGroups options.services "services")
  ++ [ "" ]
  ++ report "${user} home" {
    inherit (home) graph;
    packages = home.options.home.packages;
  } (enabledGroups home.options.programs "programs" ++ enabledGroups home.options.services "services")
)
+ "\n"
