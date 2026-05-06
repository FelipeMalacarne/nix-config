# Saradomin Home Server — NixOS + k3s Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Declare saradomin home server in nix-config (NixOS manages OS + k3s service), and clean up saradomin repo by dropping Longhorn + ArgoCD in favor of local-path storage and manual kubectl apply.

**Architecture:** NixOS declares OS-level concerns (k3s service, tailscale, openssh, restic backups, sops secrets). The saradomin repo keeps k8s manifests for application workloads, applied manually via `make apply`. Longhorn PVCs are replaced with k3s's built-in local-path-provisioner. ArgoCD bootstrap is deleted.

**Tech Stack:** NixOS 24.11, k3s, sops-nix, restic, Cloudflare R2, Tailscale, kustomize

> **Note on deploy flow:** saradomin currently runs Debian. Task 7 requires `nixos-anywhere` to wipe+install NixOS before `nixos-rebuild switch` can be used. Do Task 0 (VM test) first to rehearse this flow.

---

## File Map

### nix-config repo

| File | Action | Responsibility |
|------|--------|---------------|
| `modules/features/virtualization.nix` | Create (done) | libvirt + virt-manager for zaros |
| `hosts/saradomin-vm/default.nix` | Create (done) | VM test host mirroring saradomin |
| `modules/features/k3s.nix` | Create | k3s service + data dirs |
| `modules/features/restic.nix` | Create | Restic backup to R2 |
| `hosts/saradomin/default.nix` | Modify | Server host config (remove desktop, add server modules) |
| `hosts/saradomin/hardware.nix` | Modify | Real hardware from nixos-generate-config |
| `secrets/secrets.yaml` | Modify | Add restic password + R2 credentials |

### saradomin repo

| File | Action | Responsibility |
|------|--------|---------------|
| `kubernetes/bootstrap/` | Delete | ArgoCD bootstrap (entire dir) |
| `kubernetes/apps/data/longhorn/` | Delete | Longhorn app (entire dir) |
| `kubernetes/base/namespaces.yaml` | Modify | Remove longhorn-system namespace |
| `kubernetes/apps/data/postgres/statefulset.yaml` | Modify | Change storageClassName to local-path, remove longhorn annotation |
| `kubernetes/apps/media/*/pvc.yaml` (×9) | Modify | Change storageClassName from longhorn to local-path |
| `kubernetes/apps/networking/pihole/pvc.yaml` | Modify | Change storageClassName to local-path |
| `kubernetes/kustomization.yaml` | Create | Root kustomization replacing ArgoCD root-app |
| `Makefile` | Modify | Replace encrypt/decrypt with apply + sync targets |

---

## Task 0: Test config on a VM (do before touching real saradomin)

**Context:** saradomin runs Debian. Before wiping it with nixos-anywhere, validate the NixOS
config (k3s, sops, modules) boots and works in a local QEMU VM. `saradomin-vm` host already
created. `virtualization.nix` feature already added to zaros.

**Files:**
- Done: `modules/features/virtualization.nix`
- Done: `hosts/saradomin-vm/default.nix`
- Done: `flake.nix` (saradomin-vm entry added)

- [ ] **Step 1: Rebuild zaros to get virt-manager**

```bash
sudo nixos-rebuild switch --flake .#zaros
```

- [ ] **Step 2: Quick build-vm smoke test**

Checks if config evaluates and k3s service starts:

```bash
nix build .#nixosConfigurations.saradomin-vm.config.system.build.vm
QEMU_NET_OPTS="hostfwd=tcp::2222-:22" ./result/bin/run-saradomin-vm
```

In another terminal:
```bash
ssh -p 2222 felipe@localhost
sudo systemctl status k3s
sudo k3s kubectl get nodes
```

- [ ] **Step 3: Full nixos-anywhere rehearsal (mirrors real deploy)**

Create a blank VM in virt-manager (4GB RAM, 20GB disk, network: default NAT).
Boot NixOS minimal ISO. Note the VM IP from `ip addr`.

Then from zaros:
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#saradomin-vm \
  root@<vm-ip>
```

SSH in after install:
```bash
ssh felipe@<vm-ip>
sudo systemctl status k3s
sudo k3s kubectl get nodes
# Expected: saradomin-vm   Ready
```

- [ ] **Step 4: Verify sops secrets path (if age key placed in VM)**

```bash
sudo ls /run/secrets/
```

- [ ] **Step 5: Commit**

```bash
git add modules/features/virtualization.nix hosts/saradomin-vm/ flake.nix
git commit -m "feat(vm): add virtualization feature and saradomin-vm test host"
```

---

## Task 1: Generate hardware config on saradomin

**Context:** saradomin currently has a placeholder `hardware.nix`. Need the real one from the server.

**Files:**
- Modify: `hosts/saradomin/hardware.nix`

- [ ] **Step 1: SSH into saradomin and generate config**

```bash
ssh felipe@saradomin
sudo nixos-generate-config --show-hardware-config
```

Copy the output.

- [ ] **Step 2: Replace hardware.nix**

Replace the contents of `hosts/saradomin/hardware.nix` with the output from Step 1.
Keep only the hardware-specific parts (disk, CPU, kernel modules). Remove any
`environment.systemPackages` or other non-hardware options that nixos-generate-config adds.

- [ ] **Step 3: Commit**

```bash
git add hosts/saradomin/hardware.nix
git commit -m "feat(saradomin): add real hardware config"
```

---

## Task 2: Place age key on saradomin

**Context:** sops-nix needs the age private key at `/var/lib/sops-age/keys.txt` to decrypt secrets.
The key is stored in Bitwarden. Do this before NixOS deploy so secrets decrypt on first boot.

**Files:** none (manual server setup)

- [ ] **Step 1: SSH into saradomin**

```bash
ssh felipe@saradomin
```

- [ ] **Step 2: Create the key file**

```bash
sudo mkdir -p /var/lib/sops-age
# paste your age private key from Bitwarden:
echo "AGE-SECRET-KEY-..." | sudo tee /var/lib/sops-age/keys.txt
sudo chmod 600 /var/lib/sops-age/keys.txt
```

- [ ] **Step 3: Verify**

```bash
sudo cat /var/lib/sops-age/keys.txt | head -1
# should print: # created: ...
# or: AGE-SECRET-KEY-...
```

---

## Task 3: Write k3s NixOS module

**Files:**
- Create: `modules/features/k3s.nix`

- [ ] **Step 1: Create the module**

```nix
# modules/features/k3s.nix
#
# k3s single-node server. local-path-provisioner is k3s default storage.
# Disables built-in traefik — saradomin repo manages its own traefik helm release.
{ ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik"
    ];
  };

  # host paths that k3s pods mount via hostPath / local-path PVCs
  systemd.tmpfiles.rules = [
    "d /data/media/movies  0755 root root -"
    "d /data/media/tv      0755 root root -"
    "d /data/media/music   0755 root root -"
    "d /data/media/books   0755 root root -"
    "d /data/downloads     0755 root root -"
  ];

  # open k3s api port within tailscale interface only
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 6443 ];
}
```

- [ ] **Step 2: Commit**

```bash
git add modules/features/k3s.nix
git commit -m "feat(saradomin): add k3s NixOS module"
```

---

## Task 4: Write restic backup module

**Context:** Replaces Longhorn's R2 backup. Backs up k3s PVC data (`/var/lib/rancher/k3s/storage`)
and cluster state (`/var/lib/rancher/k3s/server/db`) to Cloudflare R2.
Secrets (restic password + R2 keys) come from sops.

**Files:**
- Create: `modules/features/restic.nix`

- [ ] **Step 1: Create the module**

```nix
# modules/features/restic.nix
#
# Restic backup of k3s PVC data and cluster state to Cloudflare R2.
# Requires sops secrets: restic-password, restic-env (R2 credentials).
{ config, ... }:
{
  sops.secrets."restic-password" = {};
  sops.secrets."restic-env" = {};

  services.restic.backups.saradomin = {
    repository = "s3:https://ACCOUNT_ID.r2.cloudflarestorage.com/saradomin-backup";
    passwordFile = config.sops.secrets."restic-password".path;
    environmentFile = config.sops.secrets."restic-env".path;
    backupPrepareCommand = ''
      mkdir -p /var/backup/postgres
    '';
    paths = [
      "/var/lib/rancher/k3s/storage"    # local-path PVC data
      "/var/lib/rancher/k3s/server/db"  # k3s SQLite cluster state
      "/var/backup/postgres"             # postgres dumps (if added later)
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
    timerConfig = {
      OnCalendar = "03:00";
      Persistent = true;
    };
  };
}
```

Replace `ACCOUNT_ID` with your actual Cloudflare account ID from the terraform config.

- [ ] **Step 2: Get Cloudflare account ID**

```bash
cat ~/repos/saradomin/terraform/cloudflare/main.tf | grep account_id
# or from .env / terraform vars
```

Update the `repository` URL in `restic.nix` with the real account ID.

- [ ] **Step 3: Add restic secrets to sops**

```bash
cd ~/repos/nix-config
EDITOR=nvim sops secrets/secrets.yaml
```

Add:
```yaml
restic-password: "a-strong-random-passphrase"
restic-env: |
  AWS_ACCESS_KEY_ID=your-r2-access-key-id
  AWS_SECRET_ACCESS_KEY=your-r2-secret-access-key
```

R2 credentials found in Cloudflare dashboard → R2 → Manage R2 API tokens,
or from `~/repos/saradomin/terraform/cloudflare/`.

- [ ] **Step 4: Commit**

```bash
git add modules/features/restic.nix secrets/secrets.yaml
git commit -m "feat(saradomin): add restic backup module"
```

---

## Task 5: Configure saradomin host

**Context:** Current `hosts/saradomin/default.nix` imports `base.nix` (which has desktop tools).
Server doesn't need fonts, btop, yazi, etc. Wire in server-specific modules.

**Files:**
- Modify: `hosts/saradomin/default.nix`

- [ ] **Step 1: Rewrite the host config**

```nix
# hosts/saradomin/default.nix
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  imports = [
    ./hardware.nix
    ../../modules/options.nix
    ../../modules/features/core.nix
    ../../modules/features/zsh.nix
    ../../modules/features/git.nix
    ../../modules/features/ssh.nix
    ../../modules/features/nvim.nix
    ../../modules/features/openssh.nix
    ../../modules/features/tailscale.nix
    ../../modules/features/sops.nix
    ../../modules/features/k3s.nix
    ../../modules/features/restic.nix
  ];

  networking.hostName = "saradomin";
  myConfig.colorScheme = "catppuccin-mocha";
  system.stateVersion = "24.11";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  users.users.${user}.openssh.authorizedKeys.keyFiles = [
    ../../keys/zaros.pub
  ];
}
```

- [ ] **Step 2: Verify the config evaluates**

```bash
cd ~/repos/nix-config
nix flake check 2>&1 | head -40
# should complete without errors (warnings OK)
```

If errors appear related to missing `hardware.nix` content, ensure Task 1 is done first.

- [ ] **Step 3: Commit**

```bash
git add hosts/saradomin/default.nix
git commit -m "feat(saradomin): configure NixOS server host"
```

---

## Task 6: Add secrets to sops for saradomin ssh key

**Context:** saradomin needs its own SSH key for git operations (no Bitwarden on server).
`ssh.nix` already declares `sops.secrets."zaros-private-key"` which places key at `~/.ssh/zaros`.
Saradomin should have its own key — add it separately.

**Files:**
- Modify: `secrets/secrets.yaml`
- Modify: `hosts/saradomin/default.nix`

- [ ] **Step 1: Generate a new key for saradomin (on saradomin or locally)**

```bash
ssh-keygen -t ed25519 -C "saradomin" -f /tmp/saradomin_key -N ""
cat /tmp/saradomin_key      # private — goes in sops
cat /tmp/saradomin_key.pub  # public — add to GitHub if needed
```

- [ ] **Step 2: Add private key to sops**

```bash
cd ~/repos/nix-config
EDITOR=nvim sops secrets/secrets.yaml
```

Add:
```yaml
saradomin-ssh-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
  -----END OPENSSH PRIVATE KEY-----
```

- [ ] **Step 3: Declare secret in saradomin host**

Add to `hosts/saradomin/default.nix` inside the config block:
```nix
sops.secrets."saradomin-ssh-key" = {
  owner = user;
  path = "/home/${user}/.ssh/id_ed25519";
  mode = "0600";
};
```

- [ ] **Step 4: Commit**

```bash
git add hosts/saradomin/default.nix secrets/secrets.yaml
git commit -m "feat(saradomin): add sops-managed SSH key"
```

---

## Task 7: Deploy NixOS to saradomin

**Context:** saradomin runs Debian — must use `nixos-anywhere` to wipe+install NixOS first.
Requires hardware.nix (Task 1) and age key placed beforehand (Task 2).
After first install, subsequent updates use `nixos-rebuild switch`.

- [ ] **Step 1: Update flake lock**

```bash
cd ~/repos/nix-config
nix flake update
```

- [ ] **Step 2: Install NixOS via nixos-anywhere (first time only)**

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#saradomin \
  root@saradomin
```

This wipes the disk and installs NixOS. SSH back in after reboot.

- [ ] **Step 3: Place age key (if not done in Task 2)**

```bash
ssh felipe@saradomin
sudo mkdir -p /var/lib/sops-age
echo "AGE-SECRET-KEY-..." | sudo tee /var/lib/sops-age/keys.txt
sudo chmod 600 /var/lib/sops-age/keys.txt
```

- [ ] **Step 4: Subsequent updates (after NixOS is installed)**

```bash
nixos-rebuild switch \
  --flake .#saradomin \
  --target-host felipe@saradomin \
  --use-remote-sudo
```

Expected: build on zaros, copy closure to saradomin, activate. May take several minutes first time.

- [ ] **Step 3: Verify k3s is running**

```bash
ssh felipe@saradomin
sudo k3s kubectl get nodes
# Expected: saradomin   Ready   control-plane   ...
sudo systemctl status k3s
# Expected: active (running)
```

- [ ] **Step 4: Verify sops secrets decrypted**

```bash
ssh felipe@saradomin
sudo ls /run/secrets/
# should list declared secrets
```

- [ ] **Step 5: Commit**

```bash
# in nix-config
git add flake.lock
git commit -m "chore: update flake lock"
```

---

## Task 8: Remove ArgoCD from saradomin repo

**Context:** ArgoCD is no longer used. Remove bootstrap manifests and all `application.yaml` ArgoCD CRD files.

**Files (saradomin repo):**
- Delete: `kubernetes/bootstrap/` (entire dir)
- Delete all `application.yaml` files (ArgoCD Application CRDs — not needed without ArgoCD)

- [ ] **Step 1: Delete ArgoCD bootstrap**

```bash
cd ~/repos/saradomin
rm -rf kubernetes/bootstrap/
```

- [ ] **Step 2: Delete all application.yaml files**

```bash
find kubernetes/apps -name "application.yaml" -delete
```

- [ ] **Step 3: Verify what remains**

```bash
find kubernetes/apps -name "*.yaml" | sort
# Should show only: deployment, service, ingress, pvc, kustomization, configmap, secrets files
# No application.yaml files
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove ArgoCD bootstrap and Application CRDs"
```

---

## Task 9: Remove Longhorn from saradomin repo

**Files (saradomin repo):**
- Delete: `kubernetes/apps/data/longhorn/` (entire dir)
- Modify: `kubernetes/base/namespaces.yaml`

- [ ] **Step 1: Delete Longhorn app dir**

```bash
cd ~/repos/saradomin
rm -rf kubernetes/apps/data/longhorn/
```

- [ ] **Step 2: Remove longhorn-system namespace**

Edit `kubernetes/base/namespaces.yaml` — remove this block:
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove Longhorn storage"
```

---

## Task 10: Migrate all PVCs from longhorn to local-path

**Context:** 9 app PVCs + postgres StatefulSet use `storageClassName: longhorn`.
Replace with `local-path` (k3s built-in default provisioner).
Also remove Longhorn-specific annotations.

**Files (saradomin repo):**
- `kubernetes/apps/data/postgres/statefulset.yaml`
- `kubernetes/apps/media/bazarr/pvc.yaml`
- `kubernetes/apps/media/jellyfin/pvc.yaml`
- `kubernetes/apps/media/prowlarr/pvc.yaml`
- `kubernetes/apps/media/qbittorrent/pvc.yaml`
- `kubernetes/apps/media/radarr/pvc.yaml`
- `kubernetes/apps/media/recyclarr/pvc.yaml`
- `kubernetes/apps/media/seerr/pvc.yaml`
- `kubernetes/apps/media/sonarr/pvc.yaml`
- `kubernetes/apps/networking/pihole/pvc.yaml`

- [ ] **Step 1: Bulk replace storageClassName**

```bash
cd ~/repos/saradomin
# replace in all pvc.yaml files
find kubernetes/apps -name "pvc.yaml" \
  -exec sed -i 's/storageClassName: longhorn/storageClassName: local-path/g' {} +
```

- [ ] **Step 2: Fix postgres StatefulSet**

Edit `kubernetes/apps/data/postgres/statefulset.yaml`:

Change:
```yaml
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: longhorn
        resources:
          requests:
            storage: 20Gi
```

And remove the Longhorn annotation:
```yaml
      annotations:
        recurring-job-group.longhorn.io/default: enabled
```

Result should be:
```yaml
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: local-path
        resources:
          requests:
            storage: 20Gi
```

- [ ] **Step 3: Verify no longhorn references remain**

```bash
grep -r "longhorn" kubernetes/
# Expected: no output
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: migrate PVCs from Longhorn to local-path"
```

---

## Task 11: Create root kustomization + update Makefile

**Context:** ArgoCD was the deploy mechanism. Replace with a root `kustomization.yaml`
that includes all apps, applied via `kubectl apply -k`.

**Files (saradomin repo):**
- Create: `kubernetes/kustomization.yaml`
- Modify: `Makefile`

- [ ] **Step 1: Create root kustomization**

```yaml
# kubernetes/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - base/namespaces.yaml
  - apps/data/postgres
  - apps/media/flaresolverr
  - apps/media/intel-gpu-plugin
  - apps/media/jellyfin
  - apps/media/qbittorrent
  - apps/media/radarr
  - apps/media/sonarr
  - apps/media/prowlarr
  - apps/media/bazarr
  - apps/media/seerr
  - apps/media/recyclarr
  - apps/media/exportarr
  - apps/networking/cert-manager
  - apps/networking/cloudflared
  - apps/networking/coredns-saradomin
  - apps/networking/pihole
  - apps/networking/tailscale
  - apps/networking/traefik
  - apps/networking/traefik-config
  - apps/monitoring/prometheus-grafana
  - apps/monitoring/grafana-dashboards
  - apps/security/vaultwarden
```

- [ ] **Step 2: Update Makefile**

Replace entire Makefile with:

```makefile
DEC_SECRETS := $(shell find kubernetes -name "*.dec.yaml")
ENC_SECRETS  := $(shell find kubernetes -name "secrets.yaml")
KUBECONFIG   ?= /etc/rancher/k3s/k3s.yaml

.PHONY: encrypt decrypt apply sync

encrypt: ## Encrypt all *.dec.yaml → secrets.yaml
	@for f in $(DEC_SECRETS); do \
		out=$$(dirname "$$f")/secrets.yaml; \
		echo "Encrypting $$f → $$out"; \
		sops -e "$$f" > "$$out"; \
	done

decrypt: ## Decrypt all secrets.yaml → *.dec.yaml
	@for f in $(ENC_SECRETS); do \
		out=$$(dirname "$$f")/$$(basename "$$f" .yaml).dec.yaml; \
		echo "Decrypting $$f → $$out"; \
		sops -d "$$f" > "$$out"; \
	done

apply: ## Apply all manifests to k3s
	kubectl apply -k kubernetes/

sync: decrypt apply ## Decrypt secrets then apply all manifests
```

- [ ] **Step 3: Verify kustomization builds**

```bash
kubectl kustomize kubernetes/
# Expected: prints all manifests, no errors
# (requires kubectl with kustomize support)
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add root kustomization and replace ArgoCD deploy with make apply"
```

---

## Task 12: First apply to k3s

**Context:** First time applying manifests to the fresh k3s cluster on saradomin.

- [ ] **Step 1: Copy kubeconfig locally (optional)**

```bash
ssh felipe@saradomin "sudo cat /etc/rancher/k3s/k3s.yaml" \
  | sed 's/127.0.0.1/100.79.221.47/' \
  > ~/.kube/saradomin.yaml
export KUBECONFIG=~/.kube/saradomin.yaml
kubectl get nodes
# Expected: saradomin   Ready
```

- [ ] **Step 2: Apply namespaces first**

```bash
cd ~/repos/saradomin
kubectl apply -f kubernetes/base/namespaces.yaml
```

- [ ] **Step 3: Apply all manifests**

```bash
make apply
# or if secrets need decrypting first:
make sync
```

- [ ] **Step 4: Verify pods come up**

```bash
kubectl get pods -A
# Watch for Running status. Some may take time to pull images.
# networking pods (traefik, coredns, tailscale) should come up first
```

- [ ] **Step 5: Verify Traefik gets Tailscale IP**

```bash
kubectl get svc -n networking traefik
# EXTERNAL-IP should show 100.79.221.47
```

- [ ] **Step 6: Test internal DNS**

From zaros (on Tailscale):
```bash
curl -k https://jellyfin.saradomin
# Expected: Jellyfin response or redirect (not connection refused)
```

---

## Task 13: Verify restic backups work

- [ ] **Step 1: Initialize restic repository**

```bash
ssh felipe@saradomin
sudo systemctl start restic-backups-saradomin.service
sudo journalctl -u restic-backups-saradomin.service -f
# Expected: "snapshot ... saved"
```

- [ ] **Step 2: List snapshots**

The repository password and env are in `/run/secrets/`. Run as root:
```bash
sudo -E bash -c '
  source /run/secrets/restic-env
  restic \
    --repository "s3:https://ACCOUNT_ID.r2.cloudflarestorage.com/saradomin-backup" \
    --password-file /run/secrets/restic-password \
    snapshots
'
# Expected: table showing at least one snapshot
```

- [ ] **Step 3: Verify timer is scheduled**

```bash
sudo systemctl status restic-backups-saradomin.timer
# Expected: active (waiting), next trigger shows 03:00
```
