# ISSUE-044: Complete or retire the dormant OpenClaw token provider

- Status: resolved
- Priority: P2
- Kind: source-confirmed dormant integration gap; no active-host outage established
- Scope: optional OpenClaw remote authentication and host-owned secret delivery
- Dependencies: none for isolated fixtures; coordinate real secret delivery with [ISSUE-012](012-sops-editing-permissions.md) and [ISSUE-043](043-darwin-sops-bootstrap.md)

## Problem And Evidence

The unselected [OpenClaw feature](../../modules/features/applications/openclaw.nix)
uses a file SecretRef with provider `sops` and a filesystem path as its ID, but
declares neither the corresponding provider nor the runtime token. In the pinned
API, a file reference's ID selects a value within its provider's file; naming a
provider `sops` does not automatically integrate sops-nix.

## Decision And Scope

Decide whether this optional integration is still wanted. If maintained, define
an actual runtime-delivered file or environment provider and let the selecting
host own the secret. Check file-provider path/security rules against SOPS symlinks.
Do not enable OpenClaw on a host simply to repair a dormant capability or place
token values in the store. If retired, remove only its proven-unused inputs.

## Acceptance Criteria

- [ ] Retention or retirement of the integration is explicitly decided.
- [ ] If retained, provider, reference ID, runtime path, and owned secret delivery agree.
- [ ] Missing/invalid credentials fail safely in an isolated fixture.
- [ ] Active host selections remain unchanged unless separately requested.

## Verification And Approval

Validate the pinned provider schema and evaluate a feature fixture; exercise
fake credentials and a mocked endpoint without contacting the real gateway.
Build any retained package/module integration. Credential provisioning, actual
gateway access, secret decryption, and activation require separate approval.
This issue does not establish that an active Zaros service is currently broken.

## Resolution

Retired: the OpenClaw module and input are removed and checks assert their absence. Legacy encrypted credentials are intentionally kept.

[Back to backlog](README.md)
