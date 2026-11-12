{
  # Trust the home-lab CA that signs Saradomin's internal service certificates.
  flake.modules.nixos.internal-ca = {
    security.pki.certificateFiles = [ ./config/saradomin-internal-ca.crt ];
  };
}
