# ISSUE-027: Review AdGuard administrative authentication and access

- Status: deferred
- Priority: P1
- Kind: source-confirmed trust policy requiring deferred security review
- Scope: Saradomin AdGuard dashboard authentication, proxy ingress, and workload access
- Dependencies: coordinate tailnet boundaries with [ISSUE-041](041-tailscale-trust-policy.md)

## Problem And Evidence

The [AdGuard feature](../../modules/features/services/adguard-home.nix) sets
`users = [ ]` and serves its dashboard on port 3000. The
[host selection](../../hosts/saradomin/default.nix) binds the dashboard to the
LAN address and allows its configured pod CIDR through the firewall, not just a
single proxy workload. The [Tailscale feature](../../modules/features/services/tailscale.nix)
also trusts the entire tailnet interface at the host firewall.

The [existing access documentation](../adguard-home.md#web-interface) explicitly
accepts LAN/tailnet administrative trust and says the public tunnel excludes
the dashboard. Its opening loopback-only description conflicts with the current
listener. These sources do not prove public Internet exposure or exploitation.

## Decision And Scope

Review whether every permitted workload and tailnet client should administer
DNS. Decide application authentication and narrowly reviewed proxy/workload
access, including credential provisioning and recovery. Correct the documented
listener/trust boundary as part of that approved policy work. Keep DNS listener
availability in [ISSUE-005](005-adguard-dns-availability.md) separate; neither
issue authorizes incidental firewall, proxy, or authentication changes.

## Acceptance Criteria

- [ ] Intended administrators and allowed proxy/workload paths are explicitly approved.
- [ ] Authentication and credential recovery are implemented or their omission explicitly accepted.
- [ ] Direct port, pod-network, LAN, and tailnet access match the reviewed boundary.
- [ ] Documentation matches the effective listener and distinguishes public exposure from internal trust.

## Verification And Approval

Begin with source-level access-path review; for an authorized implementation,
use isolated authentication/routing tests and complete formatting, evaluation,
and the affected closure build. Runtime reachability tests, workload inspection,
credential reads/changes, firewall or proxy changes, restarts, and deployment
require explicit approval. Do not infer public exposure from an empty users list
or claim runtime access restrictions were tested by this documentation task.

## Resolution

Not resolved.

[Back to backlog](README.md)
