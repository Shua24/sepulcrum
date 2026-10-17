# Bootloader, kernel and swap.
{ config, lib, pkgs, ... }:

{
  # Limine on the 4G EFI system partition at /boot, matching the CachyOS layout.
  # Snapper and limine-snapper-sync are deliberately NOT carried over: NixOS
  # generations plus `nixos-rebuild --rollback` cover the same ground, and
  # limine-snapper-sync does not exist in nixpkgs.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.limine = {
    enable = true;
    efiSupport = true;
    maxGenerations = 10;
  };

  # Vanilla kernel: linux-cachyos does not exist in nixpkgs and cachyos-settings
  # is Arch-only packaging. This is the agreed trade for a maintainable base.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "quiet" "nowatchdog" ];

  # NOTE: fileSystems is deliberately NOT defined in this tree.
  # `nixos-generate-config` writes fileSystems into
  # hardware-configuration.nix with real UUIDs, and defining them in both
  # files is a hard conflict:
  #   error: The option `fileSystems."/boot".device' has conflicting definition
  #   values: "/dev/disk/by-label/NIXOS-BOOT" vs "/dev/disk/by-uuid/1234-ABCD"
  # Verified by evaluating this tree next to the generated file.
  # Let hardware-configuration.nix own fileSystems.
  #
  # The live layout is btrfs, one filesystem per partition, no subvolumes
  # (mounted at subvolid=5, subvol=/), plus a vfat ESP:
  #   /      btrfs  label nixos-root  (nvme0n1p2)
  #   /nix   btrfs  label nixos-nix   (nvme0n1p3)
  #   /home  btrfs  label nixos-home  (nvme0n1p4)
  #   /boot  vfat   label NIXOS-BOOT  (nvme0n1p1, 1G)
  # The three btrfs partitions carry labels; the ESP was labelled later with
  # fatlabel so that a future by-label switch is a one-line edit per mount.

  zramSwap = {
    enable = true;
    # Your CachyOS zram0 was 15974006784 bytes on a 14GiB machine.
    memoryPercent = 100;
    algorithm = "zstd";
  };
}
