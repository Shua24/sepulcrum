# GPU inspection tooling and ASUS/laptop hardware utilities.
#
# A plain function of `pkgs`, not a NixOS module. The aggregator in
# modules/packages/default.nix concatenates these in the order written there,
# which keeps environment.systemPackages deterministic. Relying on module
# merge order would NOT be deterministic: the module system processes
# `imports` in reverse, so the list would silently come out backwards.
{ pkgs }:

with pkgs; [

    # --- GPU and hardware tooling
    libva-utils
    vdpauinfo
    mesa-demos
    amdgpu_top
    nvtopPackages.full
    radeontop
    cpu-x
    asusctl
    supergfxctl
    linuxPackages_latest.acpi_call
    linuxPackages_latest.cpupower
    linuxPackages.v4l2loopback
    v4l-utils
  
]
