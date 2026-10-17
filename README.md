# Sepulcrum

NixOS configuration for **sepulcrum** at NixOS `nixos-unstable`,consumed as a
flake input.

This configuration is split into modules. The split was
verified to be behaviour-neutral: the modular tree evaluates to a byte-identical
derivation to the original single file, and `nixos-rebuild build` produces a
system whose kernel, initrd, systemd, binary count and enabled-unit set all match
the current live machine.

## Critical Notes

In case the hardware changes, there are some things that can be marked as
stale or obsolete. Those things are:

- `./modules/hardware/asus-rog.nix` (specific to ASUS ROG laptops)
- `./modules/hardware/nvidia.nix` (So far I'm planning to move out to fully use AMD)
once I have the resources needed.
- `./modules/hardware/platform.nix` (Strictly in case some hardware require different
modules)

## Layout

```
flake.nix                   inputs + nixosConfigurations.sepulcrum

configuration.nix           thin aggregator: import list + stateVersion

hardware-configuration.nix  Generated via nixos-generate-config if
                            post-install owns fileSystems, initrd,
                            microcode

modules/
  core/                     identity, users, boot, nix

  hardware/                 graphics, nvidia, asus-rog

  desktop/                  sessions, fonts, input-method

  services/                 audio, system-services, security, virtualisation

  programs/                 programs, gaming

  packages/                 default.nix aggregator + 15 group files
```

## Setup

Here's a way to set the system up for installing. Keep in mind that it's not
the configuration recommended by the installer. My math are as follows:

```
/boot       around 1 GB in size, absolute
/           around 50 GB per 1TB of total space
/nix        around 150 GB per 1TB of total space
/home       The rest of the remaining space
```

Note that swap is handed into `zram` instead, so no swap needed. For *moar swap baby*
just increase swap. It's a brand new Linux + zram feature.

## How It Works

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

In case executing the bash shell directly fails, use these:

```bash
sudo bash deploy.sh             # build only
sudo bash deploy.sh --switch    # Build and activate
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
