# sepulcrum

NixOS configuration for **sepulcrum**, an ASUS ROG Strix G513RM (Radeon 680M +
RTX 3060, AMD Ryzen 6000). NixOS `nixos-unstable`, consumed as a flake input.

Migrated from CachyOS on 2026-10-17 and then split into modules. The split was
verified to be behaviour-neutral: the modular tree evaluates to a byte-identical
derivation to the original single file, and `nixos-rebuild build` produces a
system whose kernel, initrd, systemd, binary count and enabled-unit set all match
the live machine.

## Layout

```
flake.nix                 inputs + nixosConfigurations.sepulcrum
configuration.nix         thin aggregator: import list + stateVersion
hardware-configuration.nix  GENERATED - owns fileSystems, initrd, microcode
modules/
  core/                   identity, users, boot, nix
  hardware/               graphics, nvidia, asus-rog
  desktop/                sessions, fonts, input-method
  services/               audio, system-services, security, virtualisation
  programs/               programs, gaming
  packages/               default.nix aggregator + 15 group files
```

`configuration.nix` is a thin aggregator on purpose: `flake.nix` imports it and
passes `nixos-hardware` through `specialArgs`, so `nixos-rebuild --flake` works
*and* plain `nixos-rebuild switch` still works via a pinned `fetchTarball`
fallback.

## Deploy

This repo is the source of truth. `/etc/nixos` is a deploy target.

```bash
./deploy.sh            # build only, nothing activates
./deploy.sh --switch   # build and activate
```

Rollback is handled by **generations**, not by copying config trees: every
`--switch` creates a generation, Limine lists them at boot, and
`sudo nixos-rebuild --rollback switch` returns to the previous one. `deploy.sh`
keeps no backups of `/etc/nixos` — the config lives in git and the built systems
live in the store.

## Rebuild by hand

```bash
sudo nixos-rebuild switch --flake /etc/nixos#sepulcrum
```

A flake **only sees git-tracked files**. If you edit a module and rebuild
without committing, the change silently does nothing. `deploy.sh` commits for
you; if you rebuild by hand, commit first. `path:/etc/nixos#sepulcrum` bypasses
git entirely if you would rather not care.

## Update inputs

Deliberately, never by accident:

```bash
nix flake update
./deploy.sh
```

## Read this before editing

`NOTES.md` carries the full verification record and the traps: the reverse
`imports` ordering that silently reorders `environment.systemPackages`, why
`command-not-found` disappears under a flake, why the three `mkForce` calls are
load-bearing, and the unlabelled ESP. Read it before restructuring anything.
