# ASUS ROG platform services: asusd, supergfxd, battery charge threshold.
{ config, lib, pkgs, ... }:

{
  services.asusd.enable = true;
  services.supergfxd.enable = true;
  # Replaces battery-charge-threshold.service from the CachyOS install.
  # rog-control-center ships inside the asusctl package, not separately.
  # This option is declared by nixos-hardware's asus/battery.nix, which the
  # g513im module imports - it is not a NixOS core option.
  hardware.asus.battery = {
    chargeUpto = 80;
    enableChargeUptoScript = true;
  };
}
