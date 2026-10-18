# ISSUE-043: Define the Darwin SOPS bootstrap procedure

- Status: deferred
- Priority: P2
- Kind: Source-confirmed manual bootstrap gap; deferred security and recovery decision
- Scope: Darwin age-key provisioning, ownership, consumer access, and recovery
- Dependencies: Owner-approved key custody and recovery policy; coordinate ISSUE-038

## Problem And Evidence

The [Darwin SOPS module](../../modules/features/system/sops.nix#L25-L36) points
to `/var/lib/sops-age/keys.txt` but does not provision the key or its directory.
The [setup instructions](../../README.md#setup-and-secrets) rely on manual privileged
installation, while the [shared editing environment](../../modules/features/system/sops.nix#L3-L5)
points user-side SOPS at that same path. Successful access depends on existing
ownership and permissions; neither a missing key nor failed decryption was observed.

The [Linux ownership rule](../../modules/features/system/sops.nix#L19-L21)
does not establish a Darwin procedure. The
[README](../../README.md#validation-and-deferred-work) and
[AGENTS.md](../../AGENTS.md#validation-and-deployment) explicitly leave Darwin bootstrap deferred.
The gap concerns provisioning and recovery, not permission to inspect key material.

## Decision And Scope

Agree who provisions and owns the Darwin key, which root/user consumers need
access, and how first installation, replacement, and independent recovery work.
Document an out-of-store, non-logging process and intended directory/file modes.
Do not copy Linux ownership policy blindly, loosen permissions casually, embed
key values in Nix or documentation, or rotate recipients as incidental cleanup.
Keep native operational validation coordinated with [ISSUE-038](038-native-darwin-validation.md).

## Acceptance Criteria

- [ ] Provisioning responsibility and root/user consumer access are explicitly approved.
- [ ] Directory and file ownership/modes provide required access without broadening exposure.
- [ ] First-install and missing-key behavior are documented without disclosing key values.
- [ ] Recovery custody and a separately approved recovery-verification procedure are defined.
- [ ] Native bootstrap evidence or remaining deferred operational checks are recorded.

## Verification And Approval

Review the procedure and module wiring without reading keys or decrypting secrets.
For approved implementation, use dummy identities and fixture secrets first, then
format, evaluate, and build the affected closure on native Apple Silicon.
Real provisioning, permission/ownership changes, decryption, activation, and recovery
drills require separate explicit approval. Never print or copy private key values
into logs, issues, command history, or the Nix store; this entry authorizes none of them.

## Resolution

Not resolved.

[Back to backlog](README.md)
