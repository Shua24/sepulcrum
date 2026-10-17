# Users and sudo policy.
{ config, lib, pkgs, ... }:

{
  users.users.aulus = {
    isNormalUser = true;
    description = "Carolus";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "render"
      "audio"
      "input"
      "storage"
      "lp"
    ];
  };
  security.sudo.wheelNeedsPassword = true;
}
