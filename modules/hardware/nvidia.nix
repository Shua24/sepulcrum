# NVIDIA open modules plus PRIME render offload.
{ config, lib, pkgs, ... }:

{
  hardware.nvidia = {
    modesetting.enable = true;
    # GA106 (Ampere) is Turing-or-later, so the open modules are correct and
    # match your nvidia-open-dkms setup on Arch.
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # IMPORTANT: nixos-hardware's g513im module defines BOTH bus IDs plainly,
      # so both need mkForce or the module system raises a conflicting-definition
      # error. Verified by evaluation against nixos-hardware master.
      # nixos-hardware says amdgpu is PCI:05:00:0, but on this machine the
      # Radeon 680M enumerates at 06:00.0 (lspci: 0000:06:00.0).
      nvidiaBusId = lib.mkForce "PCI:1:0:0";
      amdgpuBusId = lib.mkForce "PCI:6:0:0";
    };
  };
}
