# Mesa/Vulkan/VA-API stack and the X11 driver list.
{ config, lib, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      mesa
      vulkan-loader
      vulkan-tools
      vulkan-validation-layers
      clinfo
    ];
  };

  # Radeon 680M renders by default; the RTX 3060 is used on demand via
  # `nvidia-offload <command>`.
  services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
}
