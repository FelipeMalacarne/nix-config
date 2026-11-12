{
  # Encrypted SOPS files, as a path rather than a string derived from `self`:
  # interpolating `secretsDir + "/x.yaml"` copies only that file to the store,
  # so consumers do not depend on the whole repository source.
  _module.args.secretsDir = ../../secrets;
}
