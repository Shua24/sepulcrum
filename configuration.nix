# NixOS configuration for sepulcrum (ASUS ROG Strix G513RM)
#
# Migrated from CachyOS. Channel: nixos-unstable.
# Verified against nixpkgs revision 55bfb4d7437bd4e09ab7cba58a43bd68eb310044
# (nixos-26.11pre1092090). Every attribute name below was resolved by evaluating
# nixpkgs itself, not by reading package names off the Arch install.
#
# This file does NOT partition your disk. See NOTES.md section "Install layout".

# Entry point. Everything real lives under modules/; this file is the import
# list plus the two things that cannot move (nixos-hardware resolution and
# stateVersion). Package order is deterministic and lives in
# modules/packages/default.nix, not here - the module system merges imports in
# reverse, so relying on this list's order would reverse the package list.
{ config, lib, pkgs, ... }@moduleArguments:

let
  # nixos-hardware arrives as a flake input through specialArgs when rebuilding
  # with `nixos-rebuild --flake /etc/nixos#sepulcrum`. The fetchTarball fallback
  # keeps a plain `nixos-rebuild switch` (no flake, no lock file) working, so
  # the legacy path is not broken by the flake. The two paths deliberately pin
  # differently: the flake floats to nixos-hardware master via flake.lock, the
  # fallback stays on the commit this machine was verified against.
  nixos-hardware = moduleArguments.nixos-hardware or (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixos-hardware/archive/60a624466c08787ee8303393b7d4752d1826f14f.tar.gz";
    sha256 = "sha256-BYhx89XJltnRyQeuDKHVL5eSqbbfAcOKuDts7QRsrxQ=";
  });
in
{
  imports = [
    # nixos-hardware first so the explicit overrides below take precedence.
    (nixos-hardware + "/asus/rog-strix/g513im")
    # hardware-configuration.nix is generated per machine by
    # `nixos-generate-config` and is NOT in this repository. It owns fileSystems
    # (real UUIDs), boot.initrd.availableKernelModules, kvm-amd, AMD microcode
    # and hostPlatform.
    #
    # Committing it would publish this machine's partition UUIDs, and shipping a
    # copy is actively dangerous: a hand-written or stale one defines
    # `fileSystems` a second time and the module system aborts with
    #   error: The option `fileSystems."/".device' has conflicting definition
    # values
    # which is exactly what happened when a placeholder hardware file was used
    # during the original install.
    #
    # So the import is conditional. On a real machine deploy.sh places the
    # generated file next to this one and it is picked up. Evaluating this repo
    # standalone (CI, `nix flake check`, a fresh clone) simply skips it - the
    # module set then evaluates without fileSystems, which is fine for checking
    # that options and packages resolve, and is not a bootable system.
    #
    # A fresh machine needs:  nixos-generate-config --root /mnt
  ] ++ lib.optional (builtins.pathExists ./hardware-configuration.nix)
    ./hardware-configuration.nix ++ [

    # --- core
    ./modules/core/identity.nix
    ./modules/core/users.nix
    ./modules/core/boot.nix
    ./modules/core/nix.nix

    # --- hardware
    ./modules/hardware/platform.nix
    ./modules/hardware/graphics.nix
    ./modules/hardware/nvidia.nix
    ./modules/hardware/asus-rog.nix

    # --- desktop
    ./modules/desktop/sessions.nix
    ./modules/desktop/fonts.nix
    ./modules/desktop/input-method.nix

    # --- services
    ./modules/services/audio.nix
    ./modules/services/system-services.nix
    ./modules/services/security.nix
    ./modules/services/virtualisation.nix
    ./modules/services/accessability.nix

    # --- programs
    ./modules/programs/programs.nix
    ./modules/programs/gaming.nix

    # --- packages. One aggregator; the per-group files and their order live
    # in modules/packages/default.nix.
    ./modules/packages/default.nix
  ];

  # Do not change after the first install; it gates stateful data migrations.
  system.stateVersion = "26.11";
}
