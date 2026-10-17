# Firewall, polkit and PAM integration.
{ config, lib, pkgs, ... }:

{
  networking.firewall.enable = true;
  security.polkit.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;
}
