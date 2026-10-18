# ISSUE-041: Review broad Tailscale interface trust

- Status: deferred
- Priority: P2
- Kind: source-confirmed broad trust policy with deferred security assessment
- Scope: Host firewall trust of the Tailscale interface and intended service access
- Dependencies: coordinate [ISSUE-040](040-ssh-firewall-policy.md) and [ISSUE-027](027-adguard-admin-access.md)

## Problem And Evidence

The [Tailscale feature](../../modules/features/services/tailscale.nix) declares
`tailscale0` a trusted firewall interface. This is broader host-side acceptance
than allowing selected destination ports. The
[K3s feature](../../modules/features/services/k3s.nix) separately permits its API
port on that interface, but that rule does not narrow the broader trust policy.

Tailnet ACLs/grants, peer identities, and actual reachable listeners were not
inspected. Broad host trust is not proof of public Internet exposure or a tailnet
policy bypass. [README](../../README.md#validation-and-deferred-work) and
[AGENTS.md](../../AGENTS.md#validation-and-deployment) explicitly defer this review.

## Decision And Scope

Decide whether the tailnet is an administrative trust boundary or needs
service-specific host restrictions. Inventory intended SSH, DNS, Kubernetes,
and application access and their interaction with external tailnet policy.
If narrowing trust is approved, preserve required access through an explicit
rule set and staged recovery plan. Do not silently remove trusted-interface
behavior as a side effect of another service change.

## Acceptance Criteria

- [ ] The intended tailnet trust model and its external policy assumptions are approved.
- [ ] Required services, clients, and host-firewall boundaries are documented without identifiers.
- [ ] Retained broad trust has an explicit rationale, or approved narrow rules cover intended access.
- [ ] Access and recovery verification are recorded, with untested runtime cases left open.

## Verification And Approval

Review source and a proposed service-access matrix first. For separately
authorized Nix changes, inspect generated rules and complete formatting,
evaluation, and affected closure builds. Reading live tailnet policy/state,
probing peers, modifying ACLs/grants or interface trust, restarting services,
and deployment require explicit approval. No networking or runtime inspection
is authorized by this documentation task; builds cannot prove peer isolation.

## Resolution

Not resolved.

[Back to backlog](README.md)
