# sepulcrum — modular NixOS configuration

ASUS ROG Strix G513RM. Channel: `nixos-unstable`, consumed as a flake input.
Migrated from CachyOS on 2026-10-17.

## What was proven, and how

The refactor was verified by evaluating the NixOS module system offline against
the real nixpkgs revision, not by reading the files and hoping.

**Identity gate.** The original single-file `configuration.nix` and the modular
tree were both evaluated with `nixos/lib/eval-config.nix` against nixpkgs
`55bfb4d7437bd4e09ab7cba58a43bd68eb310044` (the revision this machine runs) and
the real generated `hardware-configuration.nix`:

    original file   -> /nix/store/vvpxkbkk3sd5167drna6952v1p0r6f5r-nixos-system-sepulcrum-26.11pre1092090.55bfb4d7437b.drv
    modular tree    -> /nix/store/vvpxkbkk3sd5167drna6952v1p0r6f5r-nixos-system-sepulcrum-26.11pre1092090.55bfb4d7437b.drv

Byte-identical derivation. 858 packages both ways, `stateVersion` 26.11 both
ways. The split is behaviour-neutral: same inputs, same output.

This gate is what caught a real bug during the work. A first draft gave each
package group its own `environment.systemPackages` inside its own module, which
is the obvious design and it was **wrong**: the module system merges `imports`
in reverse, so the package list came out with `xorg-utilities` first and
`shells` last. The derivation still built and still had 858 entries, so nothing
would have failed — `system-path` would just have been assembled in a different
order. The fix is deliberate and load-bearing: each group file is a plain
function of `pkgs`, and `modules/packages/default.nix` concatenates them with
`++` in written order. Do not "simplify" that back into per-module
`environment.systemPackages`.

**Flake gate.** `nix flake metadata` resolves to nixpkgs `55bfb4d7` and
nixos-hardware `60a6244`, and `nixos-hardware`'s own nixpkgs input collapses
onto ours via `inputs.nixpkgs.follows = "nixpkgs"`. The flake evaluates to a
working `nixosConfigurations.sepulcrum`.

## One behaviour change from adopting the flake

`programs.command-not-found` is enabled automatically when
`builtins.pathExists (pkgs.path + "/programs.sqlite")`. A channel *tarball*
ships that file, so it was on. A git-based nixpkgs input does not, so it is now
off and one package (`command-not-found`) leaves `system-path`.

That is nixpkgs' own documented behaviour, not something this refactor broke,
and it is the right outcome: forcing it on would point at a `programs.sqlite`
that does not exist. If you want the feature back on a flake system, the
upstream recommendation is `programs.nix-index` (mutually exclusive with
command-not-found) or `nix-index-database`. Do not just set
`programs.command-not-found.enable = true`.

## Layout

    /etc/nixos/
      flake.nix              inputs + nixosConfigurations.sepulcrum
      flake.lock             generated; pins what you actually built
      configuration.nix      thin aggregator: import list + stateVersion
      hardware-configuration.nix
                             GENERATED. Owns fileSystems, initrd modules,
                             kvm-amd, microcode, hostPlatform.
      modules/
        core/                identity, users, boot, nix
        hardware/            graphics, nvidia, asus-rog
        desktop/             sessions, fonts, input-method
        services/            audio, system-services, security, virtualisation
        programs/            programs, gaming
        packages/            default.nix aggregator + 15 group files

`configuration.nix` is deliberately kept as a thin aggregator rather than
putting the module list in `flake.nix`. It means plain `nixos-rebuild switch`
(no flake) still works as a fallback, using the pinned `fetchTarball` branch
inside `configuration.nix`.

## Hardware: what is in the repo and what is not

Only the **partition layout** is machine-specific, so only that stays in the
generated file. Everything else about the hardware is ordinary configuration and
lives here.

| `modules/hardware/platform.nix` (repo) | `hardware-configuration.nix` (generated) |
|---|---|
| `boot.initrd.availableKernelModules` | `fileSystems.*` (real UUIDs) |
| `boot.kernelModules` (`kvm-amd`) | `swapDevices` |
| `hardware.cpu.amd.updateMicrocode` | |
| `nixpkgs.hostPlatform` | |

`hardware-configuration.nix` is gitignored and never committed. It is imported
conditionally, so a clone without it still parses; it just cannot produce a
bootable system, because NixOS asserts a root filesystem exists.

Verified both ways against nixpkgs `55bfb4d7`:

- repo `platform.nix` + a partitions-only hardware file -> `ygfjxq2m3clw03a19gzqdpyx0pqgwpjb`
- repo `platform.nix` + the full generated file -> **the same** `ygfjxq2m…`

The second case is what actually happens on this machine: both files define the
initrd list, microcode and `hostPlatform`. Lists merge, the scalars are
`mkDefault` in both so the definitions agree instead of conflicting, and
duplicate module names collapse — the resulting
`boot.initrd.availableKernelModules` contains no repeats.

## Read this before editing

**A flake only sees git-tracked files.** In a git repo, an untracked `flake.nix`
is a hard error and an untracked `modules/` is *invisible* — Nix tells you to
`git add modules`. You add a module, rebuild, and it silently does not exist.
`/etc/nixos` is a git repo for this reason; commit before every rebuild. If you
would rather not deal with that, `nixos-rebuild --flake path:/etc/nixos#sepulcrum`
reads the directory directly and ignores git.

**`hardware-configuration.nix` owns `fileSystems` — and is NOT committed.** It
is generated per machine and carries real partition UUIDs, so it is gitignored.
Do not define `fileSystems` anywhere in `modules/`: a second plain definition of
the same mount is a hard conflicting-definition error, and a stale committed copy
of this file is what caused exactly that during the original install.

Only the partition layout stays in it. Drivers, initrd modules, microcode and
`hostPlatform` are ordinary configuration and live in
`modules/hardware/platform.nix`. Verified that this split reproduces the same
derivation, and that a full generated file coexists with `platform.nix` without
conflict (lists merge, scalars are `mkDefault` in both, duplicate module names
collapse).

A fresh machine needs `nixos-generate-config --root /mnt` before deploying;
`deploy.sh` refuses to run without a hardware file rather than building a system
with no root filesystem.

**Use `path:` for the flake reference when building locally.** A plain path to a
git repo copies only *tracked* files, and `hardware-configuration.nix` is
gitignored — so under the git form it is invisible, the conditional import
vanishes, and the build dies with *"The 'fileSystems' option does not specify
your root file system"*. `deploy.sh` uses `path:$TARGET#sepulcrum` for this
reason. Do not "simplify" it back to `$TARGET#sepulcrum`.

**The ESP has no label.** `/`, `/nix` and `/home` carry labels (`nixos-root`,
`nixos-nix`, `nixos-home`) and are whole partitions — there are no btrfs
subvolumes, the mounts are `subvolid=5, subvol=/`. `/boot` (`/dev/nvme0n1p1`,
1G vfat) was unlabelled, so a by-label config could not have mounted it. Label
it if you want to switch:

    sudo fatlabel /dev/nvme0n1p1 NIXOS-BOOT

Then edit the four `fileSystems` entries in `hardware-configuration.nix` to
`/dev/disk/by-label/...`. That is a separate, separately-verifiable change; it
is not part of this refactor.

**`mkForce` is still required in three places**, each commented where it lives:
`services.displayManager.defaultSession` (plasma6 vs niri), the NVIDIA/AMD bus
IDs (nixos-hardware's g513mi module sets both plainly), and
`programs.gnupg.agent.pinentryPackage` (plasma6 vs xfce). Do not remove them.

## Rebuild

    sudo nixos-rebuild switch --flake /etc/nixos#sepulcrum

After editing anything under `modules/`, commit first or the change is invisible:

    sudo git -C /etc/nixos add -A
    sudo git -C /etc/nixos commit -m "describe the change"

Update inputs deliberately, never by accident:

    sudo nix flake update --flake /etc/nixos

## Verification harness

The offline evaluator lives in the migration kit, not in this repo:

    ~/.hermes/cache/scratch/nixmod/eval-toplevel.py <nixpkgs-tree> <module-dir>

It prints the toplevel `drvPath`, package count and `stateVersion` without
building anything, so you can prove a refactor is behaviour-neutral before
switching. Keep the expected hash above in mind when you change the tree.
