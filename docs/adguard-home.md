# AdGuard Home on Saradomin

AdGuard Home runs as a NixOS service on the Saradomin host, outside K3s. This
keeps recursive DNS and filtering available while Kubernetes is unavailable.
Its web interface is unauthenticated and therefore binds only to
`127.0.0.1:3000`.

## Split DNS

AdGuard Home listens on the Saradomin LAN and Tailscale addresses and selects
the answer from the DNS client's source network:

| Client network | DNS listener | Wildcard answer | Route |
| --- | --- | --- | --- |
| Home LAN (`10.10.0.0/22`) | `10.10.0.10:53` | `10.10.0.10` | K3s ServiceLB to Traefik |
| Tailscale (`100.64.0.0/10`) | `100.106.58.87:53` | `100.95.138.31` | Tailscale LoadBalancer to Traefik |

The canonical zone is `*.saradomin.ftm.dev.br`. The legacy `*.saradomin` zone
uses the same split answers while clients and bookmarks migrate. AAAA requests
for both private zones receive an empty successful response so clients do not
leak them to public upstreams.

Public queries use DNS-over-HTTPS upstreams and the AdGuard DNS filter. The
configuration is immutable; the service replaces local web-interface changes
on restart.

## Web interface

Use the internal HTTPS name from the home network:

`https://adguard.saradomin.ftm.dev.br`

Traefik proxies this name to the AdGuard Home listener on `10.10.0.10:3000`.
The host firewall permits that port only from the K3s pod network, so LAN
clients cannot bypass HTTPS by connecting to port 3000 directly. The dashboard
is not exposed through the public Cloudflare Tunnel.

AdGuard Home currently has no application-level login. Treat the home LAN and
tailnet as the administrative trust boundary; add dashboard authentication if
untrusted clients are later allowed onto those networks.

## TP-Link Deco

1. Reserve `10.10.0.10` for the Saradomin mini PC.
2. In the Deco app, open **More > Advanced > DHCP Server**.
3. Set the LAN/DHCP primary DNS server to `10.10.0.10`.
4. Leave secondary DNS empty. A public secondary such as `1.1.1.1` may be used
   directly by clients and would make private names fail intermittently.
5. Reconnect clients or renew their DHCP leases.

Change the LAN DHCP DNS setting, not only the Deco WAN DNS setting.

## Tailscale

In the Tailscale admin DNS settings, add `100.106.58.87` as a restricted
nameserver for `saradomin.ftm.dev.br`. Keep or add the `saradomin` restricted
zone while compatibility aliases remain in use.

## Deployment order

The old Kubernetes CoreDNS workload and AdGuard Home both require port 53.
Deploy the Gielinor change first and wait for Argo CD to prune
`coredns-saradomin`. Then activate the Saradomin NixOS configuration. Confirm
that TCP and UDP port 53 are free before activation.

Traefik serves the Let's Encrypt wildcard certificate for
`*.saradomin.ftm.dev.br`, managed by cert-manager in the Gielinor repository.
