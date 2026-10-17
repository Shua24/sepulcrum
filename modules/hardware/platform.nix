# Platform hardware: initrd modules, kernel modules, microcode, host platform.
#
# The division of responsibility with hardware-configuration.nix is deliberate:
#
#   THIS FILE (in the repo)          hardware-configuration.nix (generated)
#   ------------------------------   --------------------------------------
#   boot.initrd.availableKernelModules   fileSystems.*  (real UUIDs)
#   boot.kernelModules (kvm-amd)         swapDevices
#   hardware.cpu.amd.updateMicrocode
#   nixpkgs.hostPlatform
#
# Only the partition layout is genuinely machine-specific, so only that stays in
# the generated file. Drivers, initrd contents and microcode are ordinary
# configuration and belong in version control with everything else.
#
# Every value here matches what `nixos-generate-config` produced for this
# machine, and the two scalars are mkDefault so the generated file's own
# mkDefault definitions agree rather than conflict. Lists merge, so if the
# generated file still carries them the union is taken and duplicate module
# names are harmless to the initrd builder.
{ config, lib, pkgs, modulesPath, ... }:

{
  # Pulls in hardware the installer's scan did not detect. Idempotent with the
  # same import in the generated file - module paths are deduplicated.
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Storage and USB controllers needed to find the root filesystem at boot.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "usbhid"
    "uas"
    "usb_storage"
    "sd_mod"
    "ahci"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # AMD Zen 3+ microcode, tied to the redistributable firmware switch.
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
